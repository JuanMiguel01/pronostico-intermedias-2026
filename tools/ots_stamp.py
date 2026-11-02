"""Sella archivos con OpenTimestamps usando la libreria `opentimestamps` directamente.

Replica lo que hace `ots stamp`: hash SHA-256 del archivo, nonce aleatorio, envio del digest a varios
calendarios publicos y escritura del archivo .ots (pendiente de confirmacion en Bitcoin; `ots upgrade`
o este mismo script con --upgrade completan la prueba horas despues).
Uso: python tools/ots_stamp.py archivo [archivo ...]
Se usa porque el ejecutable `ots` falla en Windows al cargar libssl a traves de python-bitcoinlib.
"""
import os
import sys

from opentimestamps.calendar import RemoteCalendar
from opentimestamps.core.op import OpAppend, OpSHA256
from opentimestamps.core.serialize import BytesSerializationContext
from opentimestamps.core.timestamp import DetachedTimestampFile

CALENDARS = [
    "https://a.pool.opentimestamps.org",
    "https://b.pool.opentimestamps.org",
    "https://a.pool.eternitywall.com",
    "https://ots.btc.catallaxy.com",
]


def stamp(path: str) -> None:
    with open(path, "rb") as fd:
        file_ts = DetachedTimestampFile.from_fd(OpSHA256(), fd)
    nonce_ts = file_ts.timestamp.ops.add(OpAppend(os.urandom(16)))
    merkle_root = nonce_ts.ops.add(OpSHA256())
    ok = 0
    for url in CALENDARS:
        try:
            cal = RemoteCalendar(url)
            merkle_root.merge(cal.submit(merkle_root.msg))
            ok += 1
            print(f"  {url}: ok")
        except Exception as exc:  # un calendario caido no invalida el sello
            print(f"  {url}: fallo ({exc})")
    if ok == 0:
        raise SystemExit(f"Ningun calendario acepto el digest de {path}")
    ctx = BytesSerializationContext()
    file_ts.serialize(ctx)
    out = path + ".ots"
    with open(out, "wb") as f:
        f.write(ctx.getbytes())
    print(f"{out}: {ok} calendarios, digest {file_ts.file_digest.hex()}")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        stamp(p)
