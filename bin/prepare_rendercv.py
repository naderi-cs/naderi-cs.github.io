#!/usr/bin/env python3
"""Convert the site's CV data into RenderCV's input schema."""

import sys
from pathlib import Path

import yaml


def prepare_cv(source_path: Path, output_path: Path) -> None:
    data = yaml.safe_load(source_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or not isinstance(data.get("cv"), dict):
        raise ValueError("Expected a top-level 'cv' mapping")

    cv = data["cv"]
    label = cv.pop("label", None)
    if label and not cv.get("headline"):
        cv["headline"] = label

    image = cv.pop("image", None)
    if image and not cv.get("photo"):
        cv["photo"] = image

    summary = cv.pop("summary", None)
    sections = cv.setdefault("sections", {})
    if summary:
        sections.setdefault("Summary", []).append(summary)

    for section_name, entries in sections.items():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if not isinstance(entry, dict):
                continue

            if section_name.lower() == "education" and "studyType" in entry:
                entry.setdefault("degree", entry["studyType"])
                entry.pop("studyType")

            if section_name.lower() == "skills":
                if "name" in entry:
                    entry.setdefault("label", entry.pop("name"))
                if "keywords" in entry:
                    entry.setdefault("details", entry.pop("keywords"))

            end_date = entry.get("end_date")
            if isinstance(end_date, str) and end_date.lower() == "present":
                entry["end_date"] = "present"

    output_path.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False), encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: prepare_rendercv.py INPUT_YAML OUTPUT_YAML")
    prepare_cv(Path(sys.argv[1]), Path(sys.argv[2]))
