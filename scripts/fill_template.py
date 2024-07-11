from distutils.dir_util import copy_tree, remove_tree
import json
from pathlib import Path
import jinja2


PROJECT_FOLDER = Path(__file__).parent.parent
TEMPLATE_FOLDER = PROJECT_FOLDER / "template"
CONTENT_FOLDER = "content"

TARGET_FOLDER = PROJECT_FOLDER / "target"

DATA_OBJECT_NAME = "data"
DATA_OBJECT_FILE = PROJECT_FOLDER / "data.json"


class LaTeXEnvironment(jinja2.Environment):
    default_config = {
        "block_start_string": "\BLOCK{",
        "block_end_string": "}",
        "variable_start_string": "\VAR{",
        "variable_end_string": "}",
        "comment_start_string": "\#{",
        "comment_end_string": "}",
        "line_statement_prefix": "%%",
        "line_comment_prefix": "%#",
        "trim_blocks": True,
        "autoescape": False,
    }

    def __init__(self, **kwargs):
        super().__init__(**{**self.default_config, **kwargs})


class NotLaTeXFileError(ValueError):
    def __init__(self, path: Path):
        super().__init__(f"{path} is not LaTeX file")


def is_latex_file(filepath: Path):
    return filepath.suffix.lower() == ".tex"


def fill_content_file(path: Path, data: dict):
    if not is_latex_file(path):
        raise NotLaTeXFileError(path)

    content = path.read_text()
    env = LaTeXEnvironment()
    template = env.from_string(content)
    res = template.render(data=data["data"])
    path.write_text(res)


def fill_content_folder(path: Path, data: dict):
    if not (path.exists() and path.is_dir()):
        raise ValueError(f"{path} is not exists or not a directory")

    for template_file in path.iterdir():
        try:
            fill_content_file(template_file, data)
        except NotLaTeXFileError as e:
            print(f"Skipping {e}")


def prepare_target_folder(src: Path, dist: Path):
    if dist.exists() and dist.is_dir():
        remove_tree(dist)
    copy_tree(str(src), str(dist))


def load_data_from_file(filepath: Path):
    if not filepath.exists():
        raise FileNotFoundError(f"{filepath} not found")

    return json.loads(filepath.read_text())


def main():
    data = load_data_from_file(DATA_OBJECT_FILE)
    data = {DATA_OBJECT_NAME: data}
    prepare_target_folder(TEMPLATE_FOLDER, TARGET_FOLDER)
    fill_content_folder(TARGET_FOLDER / CONTENT_FOLDER, data)


if __name__ == "__main__":
    main()
