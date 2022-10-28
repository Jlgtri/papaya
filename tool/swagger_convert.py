from json import dumps, load


def process_properties(export: dict, path: str, properties: dict) -> None:
    export[path] = {}
    for key, value in properties.items():
        if not isinstance(value, dict):
            export[path][key] = dict(
                type='object',
                doc=None,
                default=None,
                nullable=True,
            )
            continue
        __type = path.removesuffix('Model') + key.capitalize() + 'Model'
        if isinstance(_type := value['type'], list):
            _type = next(_ for _ in _type if _ != 'None')
        if _type == 'array':
            process_properties(
                export,
                __type,
                value['items'].get('properties', value['items']),
            )
        if _type == 'object':
            process_properties(export, __type, value['properties'])
        export[path][key] = dict(
            type=__type + '[]' if _type in {'array', 'object'} else _type,
            doc=value.get('description'),
            default=value.get('default'),
            nullable=True,
        )


with open('swagger_modified.json') as file:
    data = load(file)

export = {}
for path, content in data['paths'].items():
    if 'get' in content and 'content' in content['get']['responses']['200']:
        schema = content['get']['responses']['200']['content'][
            'application/json'
        ]['schema']
        if schema['type'] != 'array' or (schema := schema.get('items')):
            _path = ''.join(
                _.capitalize() for _ in path.split('/') if '{' not in _
            )
            process_properties(export, f'{_path}Model', schema['properties'])


with open('models.json', 'w') as file:
    file.write(dumps(export))
