# Generates the emoji data LUA file using this as a source:
# https://github.com/iamcal/emoji-data/blob/master/emoji.json.
import json


def write_data(emojis, output):
    output.write("return {\n")
    for emoji in emojis:
        char = "".join([chr(int(c, 16)) for c in emoji["unified"].split("-")])

        for name in emoji["short_names"]:
            output.write(
                f"  {{word = '{char}', abbr = '{char} :{name}:', "
                f"filter_text = ':{name}:'}},\n"
            )
    output.write("}\n")


if __name__ == "__main__":
    with open("emoji.json") as f:
        raw_data = json.load(f)
    with open("data.lua", "w") as output:
        write_data(raw_data, output)
