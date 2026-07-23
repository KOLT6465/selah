#!/usr/bin/env python3
"""Normalize the eBible.org WEB Protestant HTML archive into Selah's JSON resource."""

from __future__ import annotations

import argparse
import html
import json
import re
from pathlib import Path


BOOKS = [
    ("GEN", "Genesis"), ("EXO", "Exodus"), ("LEV", "Leviticus"),
    ("NUM", "Numbers"), ("DEU", "Deuteronomy"), ("JOS", "Joshua"),
    ("JDG", "Judges"), ("RUT", "Ruth"), ("1SA", "1 Samuel"),
    ("2SA", "2 Samuel"), ("1KI", "1 Kings"), ("2KI", "2 Kings"),
    ("1CH", "1 Chronicles"), ("2CH", "2 Chronicles"), ("EZR", "Ezra"),
    ("NEH", "Nehemiah"), ("EST", "Esther"), ("JOB", "Job"),
    ("PSA", "Psalms"), ("PRO", "Proverbs"), ("ECC", "Ecclesiastes"),
    ("SNG", "Song of Solomon"), ("ISA", "Isaiah"), ("JER", "Jeremiah"),
    ("LAM", "Lamentations"), ("EZK", "Ezekiel"), ("DAN", "Daniel"),
    ("HOS", "Hosea"), ("JOL", "Joel"), ("AMO", "Amos"),
    ("OBA", "Obadiah"), ("JON", "Jonah"), ("MIC", "Micah"),
    ("NAM", "Nahum"), ("HAB", "Habakkuk"), ("ZEP", "Zephaniah"),
    ("HAG", "Haggai"), ("ZEC", "Zechariah"), ("MAL", "Malachi"),
    ("MAT", "Matthew"), ("MRK", "Mark"), ("LUK", "Luke"),
    ("JHN", "John"), ("ACT", "Acts"), ("ROM", "Romans"),
    ("1CO", "1 Corinthians"), ("2CO", "2 Corinthians"),
    ("GAL", "Galatians"), ("EPH", "Ephesians"), ("PHP", "Philippians"),
    ("COL", "Colossians"), ("1TH", "1 Thessalonians"),
    ("2TH", "2 Thessalonians"), ("1TI", "1 Timothy"),
    ("2TI", "2 Timothy"), ("TIT", "Titus"), ("PHM", "Philemon"),
    ("HEB", "Hebrews"), ("JAS", "James"), ("1PE", "1 Peter"),
    ("2PE", "2 Peter"), ("1JN", "1 John"), ("2JN", "2 John"),
    ("3JN", "3 John"), ("JUD", "Jude"), ("REV", "Revelation"),
]

FOOTNOTE = re.compile(r'<a\s+[^>]*class="notemark"[^>]*>.*?</a>', re.DOTALL)
VERSE = re.compile(r'<span\s+class="verse"\s+id="V(\d+)">.*?</span>(.*?)(?=<span\s+class="verse"|</div>)', re.DOTALL)
TAG = re.compile(r"<[^>]+>")
SPACE = re.compile(r"\s+")


def suitable(text: str) -> bool:
    words = text.split()
    if not 9 <= len(words) <= 62 or not 55 <= len(text) <= 360:
        return False
    if not text[0].isupper() and text[0] not in "“‘\"":
        return False
    lowered = text.lower()
    list_signals = ("begat", "genealogy of", "descendants of", "sons of", "their divisions")
    if any(signal in lowered for signal in list_signals) and text.count(",") >= 3:
        return False
    if sum(ch.isdigit() for ch in text) >= 8:
        return False
    return True


def parse_chapter(path: Path, book: str, code: str) -> list[dict]:
    match = re.fullmatch(rf"{re.escape(code)}(\d{{2,3}})\.htm", path.name)
    if not match:
        return []
    chapter = int(match.group(1))
    source = path.read_text(encoding="utf-8-sig")
    source = FOOTNOTE.sub("", source)
    results = []
    for verse_match in VERSE.finditer(source):
        number = int(verse_match.group(1))
        text = html.unescape(TAG.sub("", verse_match.group(2)))
        text = SPACE.sub(" ", text).strip()
        if suitable(text):
            results.append({
                "id": f"{code}.{chapter}.{number}",
                "book": book,
                "bookCode": code,
                "chapter": chapter,
                "verse": number,
                "text": text,
            })
    return results


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    verses = []
    counts = {}
    for code, book in BOOKS:
        book_verses = []
        for path in sorted(args.source.glob(f"{code}[0-9][0-9]*.htm")):
            book_verses.extend(parse_chapter(path, book, code))
        if not book_verses:
            raise SystemExit(f"No verses parsed for {book} ({code})")
        counts[book] = len(book_verses)
        verses.extend(book_verses)

    payload = {
        "schemaVersion": 1,
        "translation": "World English Bible",
        "translationAbbreviation": "WEB",
        "source": "https://ebible.org/engwebp/",
        "license": "Public Domain",
        "verses": verses,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(verses):,} verses across {len(counts)} books to {args.output}")


if __name__ == "__main__":
    main()
