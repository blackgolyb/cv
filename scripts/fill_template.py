import json
from dataclasses import dataclass
from distutils.dir_util import copy_tree, remove_tree
from pathlib import Path
from typing import Protocol

import click
import jinja2
import requests

PROJECT_FOLDER = Path(__file__).parent.parent
TEMPLATE_FOLDER = PROJECT_FOLDER / "template"
CONTENT_FOLDER = "content"

BUILD_FOLDER = PROJECT_FOLDER / "build"

DATA_OBJECT_NAME = "data"


class IDataLoader(Protocol):
    def load(self) -> dict:
        raise NotImplementedError


@dataclass
class FileDataLoader(IDataLoader):
    filepath: Path

    def load(self) -> dict:
        if not self.filepath.exists():
            raise FileNotFoundError(f"{self.filepath} not found")

        return json.loads(self.filepath.read_text())


@dataclass
class HttpDataLoader(IDataLoader):
    url: str

    def load(self) -> dict:
        response = requests.get(self.url)
        return response.json()


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


def is_latex_file(filepath: Path) -> bool:
    return filepath.suffix.lower() == ".tex"


def fill_content_file(path: Path, data: dict) -> None:
    if not is_latex_file(path):
        raise NotLaTeXFileError(path)

    content = path.read_text()
    env = LaTeXEnvironment()
    template = env.from_string(content)
    res = template.render(data=data["data"])
    path.write_text(res)


def fill_content_folder(path: Path, data: dict) -> None:
    if not (path.exists() and path.is_dir()):
        raise ValueError(f"{path} is not exists or not a directory")

    for template_file in path.iterdir():
        try:
            fill_content_file(template_file, data)
        except NotLaTeXFileError as e:
            print(f"Skipping {e}")


def prepare_build_folder(src: Path, dist: Path) -> None:
    if dist.exists() and dist.is_dir():
        remove_tree(dist)
    copy_tree(str(src), str(dist))


@click.command()
@click.option(
    "-f", "--file", "filepath", type=click.Path(exists=True), help="Path to the file"
)
@click.option("-u", "--url", "url", type=click.STRING, help="URL of the web page")
def main(filepath: str, url: str) -> None:
    if filepath and url:
        raise click.UsageError(
            "You can't use both --file and --url options at the same time."
        )
    elif not filepath and not url:
        raise click.UsageError("You must specify either --file or --url option.")
    elif filepath:
        data_loader = FileDataLoader(Path(filepath))
    elif url:
        data_loader = HttpDataLoader(url)

    data = data_loader.load()
    data = {DATA_OBJECT_NAME: data}
    prepare_build_folder(TEMPLATE_FOLDER, BUILD_FOLDER)
    fill_content_folder(BUILD_FOLDER / CONTENT_FOLDER, data)


if __name__ == "__main__":
    main()
