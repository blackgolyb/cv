import json
import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Protocol

import click
import jinja2
import requests
from pydantic_settings import BaseSettings

PROJECT_DIR = Path(__file__).parent.parent


class Settings(BaseSettings):
    theme: str = "base"
    content_dir: str = "content"
    data_object_name: str = "data"
    project_dir: Path = PROJECT_DIR
    cv_file_name: str
    build_dir: Path

    @property
    def template_dir(self) -> Path:
        return self.project_dir / "template"

    @property
    def config_file(self) -> Path:
        return self.build_dir / ".config"

    @property
    def settings_file(self) -> Path:
        return self.build_dir / "settings.tex"


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


def format_date(iso: str) -> str:
    """Format an ISO date string (YYYY-MM or YYYY) into 'Mon YYYY' or 'YYYY'."""
    iso = iso.strip()
    try:
        return datetime.strptime(iso, "%Y-%m").strftime("%b %Y")
    except ValueError:
        pass
    try:
        return datetime.strptime(iso, "%Y").strftime("%Y")
    except ValueError:
        pass
    return iso


def format_period(start: str, end: str | None) -> str:
    """Format a startDate/endDate pair into a LaTeX date range string."""
    start_fmt = format_date(start)
    end_fmt = "Present" if end is None else format_date(end)
    return f"{start_fmt} -- {end_fmt}"


class LaTeXEnvironment(jinja2.Environment):
    default_config = {
        "block_start_string": "\\BLOCK{",
        "block_end_string": "}",
        "variable_start_string": "\\VAR{",
        "variable_end_string": "}",
        "comment_start_string": "\\#{",
        "comment_end_string": "}",
        "line_statement_prefix": "%%",
        "line_comment_prefix": "%#",
        "trim_blocks": True,
        "autoescape": False,
    }

    def __init__(self, **kwargs):
        super().__init__(**{**self.default_config, **kwargs})
        self.filters["format_period"] = format_period


class NotLaTeXFileError(ValueError):
    def __init__(self, path: Path):
        super().__init__(f"{path} is not LaTeX file")


def is_latex_file(filepath: Path) -> bool:
    return filepath.suffix.lower() == ".tex"


def fill_template_file(template_file: Path, template_args: dict) -> None:
    if not is_latex_file(template_file):
        raise NotLaTeXFileError(template_file)

    content = template_file.read_text()
    env = LaTeXEnvironment()
    template = env.from_string(content)
    res = template.render(template_args)
    template_file.write_text(res)


def fill_all_template_files_in_directory(template_dir: Path, template_args: dict) -> None:
    if not (template_dir.exists() and template_dir.is_dir()):
        raise ValueError(f"{template_dir} is not exists or not a directory")

    for template_file in template_dir.iterdir():
        try:
            fill_template_file(template_file, template_args)
        except NotLaTeXFileError as e:
            print(f"Skipping {e}")


def copy_filetree_from_scratch(src: Path, dist: Path) -> None:
    if dist.exists() and dist.is_dir():
        shutil.rmtree(dist)
    shutil.copytree(src, dist)


def prepare_filename_for_path(filename: str) -> str:
    return filename.replace(" ", "_").replace("/", "_")


def fill_config_file(settings: Settings, data: dict) -> None:
    allowed_keys = ("lastName", "firstName", "position", "city")
    cv_file_name = settings.cv_file_name.format(
        **{key: prepare_filename_for_path(data.get(key, "")) for key in allowed_keys}
    )
    content = f"RESULT_FILENAME={cv_file_name}\n"
    with settings.config_file.open("w") as f:
        f.write(content)


def fill_settings_file(settings: Settings):
    content = f"\\newcommand{{\\theme}}{{{settings.theme}}}\n"
    with settings.settings_file.open("w") as f:
        f.write(content)


def load_settings() -> Settings:
    return Settings()


@click.command()
@click.option("-f", "--file", "filepath", type=click.Path(exists=True), help="Path to the file")
@click.option("-u", "--url", "url", type=click.STRING, help="URL of the web page")
def main(filepath: str, url: str) -> None:
    if filepath and url:
        raise click.UsageError("You can't use both --file and --url options at the same time.")
    elif not filepath and not url:
        raise click.UsageError("You must specify either --file or --url option.")
    elif filepath:
        data_loader = FileDataLoader(Path(filepath))
    elif url:
        data_loader = HttpDataLoader(url)

    settings = load_settings()

    data = data_loader.load()
    dataForRenderer = {settings.data_object_name: data}

    copy_filetree_from_scratch(settings.template_dir, settings.build_dir)

    content_dir_in_build_folder = settings.build_dir / settings.content_dir
    fill_all_template_files_in_directory(content_dir_in_build_folder, dataForRenderer)
    fill_settings_file(settings)
    fill_config_file(settings, data)


if __name__ == "__main__":
    main()
