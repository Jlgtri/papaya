from json import dumps, load
from typing import Dict, Final, Iterable, Mapping, Type

TypesDict: Final[Dict[Type, str]] = {
    int: 'integer',
    float: 'float',
    str: 'string',
    bool: 'boolean',
}


def process_properties(export: dict, path: str, properties: dict) -> None:
    export[path] = {}
    for key, value in properties.items():
        __type = (
            path.removesuffix('Model')
            + ''.join(_[0].title() + _[1:] for _ in key.split('_') if _)
            + 'Model'
        )
        if not isinstance(value, dict):
            is_iter = False
            if is_object := isinstance(value, Mapping):
                process_properties(export, __type, value)
            elif not isinstance(value, str) and isinstance(value, Iterable):
                is_iter = True
                for item in value or ({},):
                    if isinstance(item, Mapping):
                        process_properties(export, __type, item)

            if key not in export[path]:
                export[path][key] = dict(
                    type=__type + '[]'
                    if is_iter
                    else __type
                    if is_object
                    else TypesDict.get(type(value), type(value).__name__)
                    if value is not None
                    else 'object',
                    nullable=True,
                )
                if '_' not in key:
                    export[path][key]['name'] = key
            elif export[path][key]['type'] == 'object':
                export[path][key]['type'] = (
                    __type + '[]'
                    if is_iter
                    else __type
                    if is_object
                    else TypesDict.get(type(value), type(value).__name__)
                    if value is not None
                    else 'object'
                )
            continue
        if isinstance(_type := value['type'], list):
            _type = next(_ for _ in _type if _ != 'None')
        if _type == 'array':
            items = value.get('items', {})
            if items := items.get('properties', items):
                process_properties(export, __type, items)
            elif items := value.get('example', []):
                for item in items:
                    process_properties(export, __type, item)
            else:
                return
        elif _type == 'object':
            process_properties(export, __type, value['properties'])
        export[path][key] = dict(
            type=__type + '[]'
            if _type == 'array'
            else __type
            if _type == 'object'
            else _type,
            doc=value.get('description'),
            nullable=True,
        )
        if '_' not in key:
            export[path][key]['name'] = key


with open('./tool/swagger_modified.json') as file:
    data = load(file)

export = {}
for path, content in data['paths'].items():
    _path = ''.join(
        __[0].title() + __[1:]
        for _ in path.split('/')
        for __ in _.split('_')
        if _ and '{' not in _ and __
    )
    resp_schema = next(iter(content.values()), {})
    for schema_path in (
        *('responses', '200', 'content'),
        *('application/json', 'schema'),
    ):
        resp_schema = resp_schema.get(schema_path, {})
    if (resp_schema and resp_schema.get('type') != 'array') or (
        resp_schema := resp_schema.get('items')
    ):
        process_properties(
            export, f'{_path}Model', resp_schema.get('properties', {})
        )

# for path, content in data['paths'].items():
#     _path = ''.join(
#         (_[0].title() + _[1:]) for _ in path.split('/') if _ and '{' not in _
#     )

#     req_schema = next(iter(content.values()), {})
#     for schema_path in (
#         *('requestBody', 'content', 'application/json', 'schema'),
#     ):
#         req_schema = req_schema.get(schema_path, {})
#     if (req_schema and req_schema.get('type') != 'array') or (
#         req_schema := req_schema.get('items')
#     ):
#         process_properties(
#             export, f'{_path}RequestModel', req_schema.get('properties', {})
#         )


with open('./tool/models.json', 'w') as file:
    file.write(dumps(export))
