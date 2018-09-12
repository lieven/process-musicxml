# ProcessMusicXML

Command-line tool to automate some repetitive operations on music scores.

## Building

```
swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12
```

## Commands

### choirVariations

Extracts Mezzo and Baritone parts from the second voices of Soprano/Alto/Tenor/Bass parts.

### choirMP3

Uses MuseScore to export each choir part of a score as a separate MP3 file, with other voices at 33% volume
