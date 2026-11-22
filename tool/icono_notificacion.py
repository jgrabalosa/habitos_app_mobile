"""Genera el icono pequeño de las notificaciones de Android (`ic_stat_norday`).

Android pinta el icono pequeño de una notificación solo con su transparencia:
tiene que ser blanco sobre transparente. Se saca de la brújula de la marca
(`assets/branding/simbolo_negativo.png`) sin las marcas finas del aro, que a
24 px se emborronan: una apertura morfológica (mínimo y después máximo, de 15
px sobre el original de 1024) las quita y deja la estrella y la N.

Uso, desde la raíz del repo (necesita Pillow):

    python3 tool/icono_notificacion.py

Escribe `android/app/src/main/res/drawable-<densidad>/ic_stat_norday.png` en
las cinco densidades (24, 36, 48, 72 y 96 px).
"""

from pathlib import Path

from PIL import Image, ImageFilter

ORIGEN = Path("assets/branding/simbolo_negativo.png")
RES = Path("android/app/src/main/res")
TAMANOS = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}
APERTURA = 15
# Aire alrededor, como en los iconos de sistema de Android (unos 2 dp de 24).
MARGEN = 2 / 24


def silueta() -> Image.Image:
    alfa = Image.open(ORIGEN).convert("RGBA").getchannel("A")
    alfa = alfa.point(lambda v: 255 if v > 128 else 0)
    alfa = alfa.crop(alfa.getbbox())
    ancho, alto = alfa.size
    lado = max(ancho, alto)
    cuadrado = Image.new("L", (lado, lado), 0)
    cuadrado.paste(alfa, ((lado - ancho) // 2, (lado - alto) // 2))
    abierto = cuadrado.filter(ImageFilter.MinFilter(APERTURA))
    abierto = abierto.filter(ImageFilter.MaxFilter(APERTURA))
    abierto = abierto.crop(abierto.getbbox())
    ancho, alto = abierto.size
    lado = round(max(ancho, alto) / (1 - 2 * MARGEN))
    final = Image.new("L", (lado, lado), 0)
    final.paste(abierto, ((lado - ancho) // 2, (lado - alto) // 2))
    return final


def main() -> None:
    mascara = silueta()
    for densidad, px in TAMANOS.items():
        alfa = mascara.resize((px, px), Image.LANCZOS)
        icono = Image.new("RGBA", (px, px), (255, 255, 255, 0))
        icono.putalpha(alfa)
        destino = RES / f"drawable-{densidad}" / "ic_stat_norday.png"
        destino.parent.mkdir(parents=True, exist_ok=True)
        icono.save(destino, optimize=True)
        print(destino, px)


if __name__ == "__main__":
    main()
