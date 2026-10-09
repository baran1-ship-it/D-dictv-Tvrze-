"""Fetch the locked CC0 texture maps before opening/exporting the project."""
import concurrent.futures,hashlib,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def download(entry):
    dest=ROOT/entry['path']
    if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest()==entry['sha256']: return
    req=urllib.request.Request(entry['url'],headers={'User-Agent':'DedictviTvrze/0.4 CC0 materials'})
    data=urllib.request.urlopen(req,timeout=60).read()
    if hashlib.sha256(data).hexdigest()!=entry['sha256']: raise ValueError('Checksum mismatch: '+entry['path'])
    dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
    print('Fetched '+entry['path'],flush=True)
if __name__=='__main__':
    manifest=json.loads((ROOT/'assets/materials/pbr/sources.json').read_text())
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: list(pool.map(download,manifest['files']))
