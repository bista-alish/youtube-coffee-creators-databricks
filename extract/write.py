import json

def write_jsonl(directory, file_name, rows):

    directory.mkdir(parents=True, exist_ok=True)

    path = directory / file_name
    temp_path = directory / f".{file_name}.tmp"

    with temp_path.open("w", encoding = "utf-8", newline="\n") as file:
        for row in rows:
            file.write(json.dumps(row, ensure_ascii=False) + "\n")


    temp_path.replace(path)

    with path.open(encoding="utf-8") as file:
        written = [json.loads(line) for line in file]
    return path, len(written)