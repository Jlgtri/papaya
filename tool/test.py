from json import dump, load
from pathlib import Path

root = Path(Path(__file__).parent, 'models')
for path in root.rglob('*'):
    if not path.is_file():
        continue
    export_path = root.parent / 'export_models' / path.relative_to(root)
    export_path.parent.mkdir(parents=True, exist_ok=True)
    with open(export_path, 'w') as exp:
        with open(path) as imp:
            dump({k: {'fields': v} for k, v in load(imp).items()}, exp)
