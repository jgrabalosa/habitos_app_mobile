#!/usr/bin/env python3
"""Redimensiona y comprime las imagenes de la mascota, sobrescribiendolas.

Las ilustraciones llegan a 1024x1024 y ~1,4 MB cada una. A 512 px se ven
igual de bien en la app (el widget mas grande las pinta a 140 px) y el APK
deja de cargar megas por cada estado de cada fase.

Uso (desde cualquier sitio, las rutas se resuelven desde el repo):

    pip install Pillow
    python3 scripts/optimizar_mascota.py                 # assets/mascota/
    python3 scripts/optimizar_mascota.py --tamano 256
    python3 scripts/optimizar_mascota.py --forzar        # reprocesa las ya hechas
    python3 scripts/optimizar_mascota.py assets/avatares # otra carpeta

Pensado para reutilizarse cuando lleguen las 6 imagenes de Cria y Adulto:
basta con dejarlas en la carpeta y volver a lanzarlo.
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Falta Pillow. Instalalo con:  pip install Pillow")

RAIZ = Path(__file__).resolve().parent.parent
CARPETA_POR_DEFECTO = "assets/mascota"


def humano(n_bytes: int) -> str:
    return f"{n_bytes / 1024:.0f} KB" if n_bytes < 1024 * 1024 else f"{n_bytes / 1024 / 1024:.2f} MB"


def optimizar(ruta: Path, tamano: int, colores: int, forzar: bool) -> tuple[int, int]:
    """Devuelve (bytes antes, bytes despues). Iguales si se salta el fichero."""
    antes = ruta.stat().st_size
    with Image.open(ruta) as img:
        # RGBA siempre: es lo que conserva el fondo transparente.
        img = img.convert("RGBA")
        ancho, alto = img.size

        # Idempotencia: sin esto, relanzar el script volveria a cuantizar una
        # imagen ya cuantizada y la degradaria un poco mas en cada pasada.
        if not forzar and max(ancho, alto) <= tamano and antes < 400 * 1024:
            print(f"  {ruta.name:28} {humano(antes):>9}  (ya optimizada, se salta)")
            return antes, antes

        if max(ancho, alto) > tamano:
            img.thumbnail((tamano, tamano), Image.LANCZOS)

        # Dos candidatos: RGBA comprimido al maximo, y paleta de <=256 colores.
        # FASTOCTREE es el unico metodo de quantize que respeta el canal alfa.
        rgba = ruta.with_suffix(".rgba.tmp")
        img.save(rgba, "PNG", optimize=True, compress_level=9)

        paleta = ruta.with_suffix(".pal.tmp")
        img.quantize(colors=colores, method=Image.FASTOCTREE).save(
            paleta, "PNG", optimize=True, compress_level=9
        )

        ganador = min(rgba, paleta, key=lambda p: p.stat().st_size)
        despues = ganador.stat().st_size

        # Solo se pisa el original si de verdad hemos ganado algo.
        if despues < antes:
            ganador.replace(ruta)
            modo = "paleta" if ganador is paleta else "rgba"
            print(f"  {ruta.name:28} {humano(antes):>9} -> {humano(despues):>9}"
                  f"  ({ancho}x{alto} -> {img.size[0]}x{img.size[1]}, {modo})")
        else:
            despues = antes
            print(f"  {ruta.name:28} {humano(antes):>9}  (no se gana nada, se deja)")

        for tmp in (rgba, paleta):
            tmp.unlink(missing_ok=True)

    return antes, despues


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("carpeta", nargs="?", default=CARPETA_POR_DEFECTO,
                   help=f"carpeta con los PNG (por defecto {CARPETA_POR_DEFECTO})")
    p.add_argument("--tamano", type=int, default=512, help="lado maximo en px (512)")
    p.add_argument("--colores", type=int, default=256, help="colores de la paleta (256)")
    p.add_argument("--forzar", action="store_true", help="reprocesa aunque ya este optimizada")
    args = p.parse_args()

    carpeta = Path(args.carpeta)
    if not carpeta.is_absolute():
        carpeta = RAIZ / carpeta
    if not carpeta.is_dir():
        sys.exit(f"No existe la carpeta: {carpeta}")

    pngs = sorted(carpeta.glob("*.png"))
    if not pngs:
        sys.exit(f"No hay PNG en {carpeta}")

    print(f"{carpeta.relative_to(RAIZ)} — {len(pngs)} PNG, lado maximo {args.tamano}px\n")
    total_antes = total_despues = 0
    for png in pngs:
        antes, despues = optimizar(png, args.tamano, args.colores, args.forzar)
        total_antes += antes
        total_despues += despues

    ahorro = total_antes - total_despues
    pct = (ahorro / total_antes * 100) if total_antes else 0
    print(f"\nTotal: {humano(total_antes)} -> {humano(total_despues)}"
          f"  (-{humano(ahorro)}, -{pct:.0f}%)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
