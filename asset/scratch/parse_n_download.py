

import re
def parse_url(line):
  match = re.search(r'(href|src)=[\'"]?([^\'" >]+)', line)
  if match:
    print match.group(2)

with open('mit.html') as f:
    for line in f:
        parse_url(line)
