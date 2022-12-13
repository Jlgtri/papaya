from json import dump, load
from typing import Any, Iterable, Mapping


def main(path: str, export_path: str, /, root_name: str) -> None:
    with open(path, encoding='utf-8') as file:
        data = load(file)

    result: dict = {}
    if isinstance(data, Mapping):
        process_properties(result, root_name, data)
    elif isinstance(data, Iterable):
        for item in data or ({},):
            process_properties(result, root_name, item)

    with open(export_path, 'w', encoding='utf-8') as file:
        dump(result, file)


def process_properties(
    export: Mapping[str, Any],
    path: str,
    properties: Mapping[str, Any],
) -> None:
    if path not in export:
        export[path] = {}
    for key, value in properties.items():
        _key = ''.join(_.capitalize() for _ in key.split('_') if _)
        _path = path.removesuffix('Model') + _key + 'Model'
        is_iter = False
        if is_object := isinstance(value, Mapping):
            process_properties(export, _path, value)
        elif not isinstance(value, str) and isinstance(value, Iterable):
            is_iter = True
            for item in value or ({},):
                if isinstance(item, Mapping):
                    process_properties(export, _path, item)

        if key not in export[path]:
            export[path][key] = dict(
                type=_path + '[]'
                if is_iter
                else _path
                if is_object
                else value.__class__.__name__
                if value is not None
                else 'object',
                nullable=True,
            )
        elif export[path][key]['type'] == 'object':
            export[path][key]['type'] = (
                _path + '[]'
                if is_iter
                else _path
                if is_object
                else value.__class__.__name__
                if value is not None
                else 'object'
            )


if __name__ == '__main__':
    main('tool/storyblock.json', 'tool/export_storyblock.json', 'FlagsModel')
