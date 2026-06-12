"""Actualiza la ficha de Play Store de la app via Google Play Developer API.

Uso:
    python update_listing.py show              # muestra el estado actual (solo lectura)
    python update_listing.py apply             # sube textos + imagenes y commitea
    python update_listing.py apply --notes     # ademas reescribe las notas de la release beta actual

Requiere una service account JSON en playstore/keys/ (o env PLAY_SA_JSON)
con acceso a la app en Play Console (permiso "Administrar presencia en Google Play Store").
"""

from __future__ import annotations

import glob
import json
import os
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE = "com.nestorfar.stampcamera"
NOTES_TRACK = "AYG TESTER"  # track de prueba cerrada donde viven las releases visibles
HERE = Path(__file__).parent
ASSETS = HERE / "assets"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

IMAGES = {
    "icon": ASSETS / "icon_512.png",
    "featureGraphic": ASSETS / "feature_graphic_1024x500.png",
}


def get_service():
    key_path = os.environ.get("PLAY_SA_JSON")
    if not key_path:
        candidates = glob.glob(str(HERE / "keys" / "*.json"))
        if not candidates:
            sys.exit("No hay JSON de service account en playstore/keys/ (o define PLAY_SA_JSON).")
        key_path = candidates[0]
    creds = service_account.Credentials.from_service_account_file(key_path, scopes=SCOPES)
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def show(service):
    edits = service.edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
    try:
        listings = edits.listings().list(packageName=PACKAGE, editId=edit_id).execute()
        print("=== Listings actuales ===")
        for lst in listings.get("listings", []):
            print(f"\n[{lst['language']}]")
            print(f"  title: {lst.get('title')}")
            print(f"  short: {lst.get('shortDescription')}")
            print(f"  full : {(lst.get('fullDescription') or '')[:120]}...")
        for track_name in ("beta", "production"):
            try:
                track = edits.tracks().get(packageName=PACKAGE, editId=edit_id, track=track_name).execute()
                print(f"\n=== Track {track_name} ===")
                for rel in track.get("releases", []):
                    print(f"  {rel.get('name')} status={rel.get('status')} versionCodes={rel.get('versionCodes')}")
                    for note in rel.get("releaseNotes", []):
                        print(f"    notas[{note['language']}]: {note['text'][:100]}")
            except Exception as e:
                print(f"\n(track {track_name}: {e})")
    finally:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()


def apply(service, update_notes: bool):
    cfg = json.loads((HERE / "listing.json").read_text(encoding="utf-8"))
    lang = cfg["language"]
    edits = service.edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]

    edits.listings().update(
        packageName=PACKAGE,
        editId=edit_id,
        language=lang,
        body={
            "language": lang,
            "title": cfg["title"],
            "shortDescription": cfg["shortDescription"],
            "fullDescription": cfg["fullDescription"],
        },
    ).execute()
    print(f"Textos actualizados ({lang}).")

    for image_type, path in IMAGES.items():
        if not path.exists():
            print(f"  (sin {image_type}: {path.name} no existe, lo salto)")
            continue
        edits.images().deleteall(
            packageName=PACKAGE, editId=edit_id, language=lang, imageType=image_type
        ).execute()
        edits.images().upload(
            packageName=PACKAGE,
            editId=edit_id,
            language=lang,
            imageType=image_type,
            media_body=MediaFileUpload(str(path), mimetype="image/png"),
        ).execute()
        print(f"Imagen {image_type} subida: {path.name}")

    if update_notes:
        track = edits.tracks().get(packageName=PACKAGE, editId=edit_id, track=NOTES_TRACK).execute()
        for rel in track.get("releases", []):
            if rel.get("status") == "completed":
                rel["releaseNotes"] = [{"language": lang, "text": cfg["releaseNotes"]}]
        edits.tracks().update(
            packageName=PACKAGE, editId=edit_id, track=NOTES_TRACK, body=track
        ).execute()
        print(f"Notas de la release activa en '{NOTES_TRACK}' reescritas.")

    edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    print("\nCommit OK — los cambios pueden tardar unos minutos/horas en reflejarse en Play Store.")


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("show", "apply"):
        sys.exit(__doc__)
    service = get_service()
    if args[0] == "show":
        show(service)
    else:
        apply(service, update_notes="--notes" in args)


if __name__ == "__main__":
    main()
