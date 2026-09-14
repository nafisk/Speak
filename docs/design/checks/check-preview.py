"""Static design checks. Run: python3 docs/design/checks/check-preview.py"""
from html.parser import HTMLParser
from pathlib import Path
import json
import re
import subprocess

root = Path(__file__).resolve().parents[1]
source = (root / 'speak-theme.html').read_text()

class Markup(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
    def handle_starttag(self, tag, attrs):
        assert tag not in ('html', 'head', 'body'), 'Expected a fragment'
        self.ids.extend(value for key, value in attrs if key == 'id')

markup = Markup()
markup.feed(source)
assert len(markup.ids) == len(set(markup.ids)), 'Duplicate IDs'
refs = set(re.findall(r"el\('([^']+)'\)", source))
assert refs <= set(markup.ids), refs - set(markup.ids)
script = re.search(r'<script>(.*?)</script>', source, re.S).group(1)
subprocess.run(['node', '--check', '--input-type=commonjs'], input=script, text=True, check=True)
assert not re.search(r'\b(fetch|XMLHttpRequest|WebSocket|getUserMedia)\s*\(', script), 'Preview must stay simulated'

def luminance(value):
    channels = [int(value[i:i+2], 16) / 255 for i in (1, 3, 5)]
    return sum(weight * (c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4)
               for weight, c in zip((.2126, .7152, .0722), channels))

tokens = json.loads((root / 'tokens.json').read_text())
for mode in ('light', 'dark'):
    colors = {key: value[mode] for key, value in tokens['colors'].items()}
    for foreground, background in [('textPrimary', 'content'), ('textSecondary', 'content'),
                                   ('textSecondary', 'window'), ('textSecondary', 'chromeFallback'),
                                   ('onAccent', 'accent')]:
        low, high = sorted((luminance(colors[foreground]), luminance(colors[background])))
        ratio = (high + .05) / (low + .05)
        assert ratio >= 4.5, (mode, foreground, background, ratio)
        print(f'{mode}: {foreground}/{background} = {ratio:.2f}:1')
print(f'PASS: syntax, {len(markup.ids)} unique IDs, {len(refs)} element references, opaque text contrast.')
print('Rendering, runtime interactions, and native macOS behavior require separate verification.')
