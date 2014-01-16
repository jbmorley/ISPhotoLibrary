#!/usr/bin/env python

import argparse
import os
import json
import hashlib
import os.path
import wsgiref.simple_server

# Use the 'photos' directory next to the script by default.
directory = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'photos')

class Index:

  def __init__(self, directory):

    self.directory = directory
    self.index = {}

    # List the directory.
    for (dirpath, dirnames, filenames) in os.walk(directory):
      for filename in filenames:
        md5 = hashlib.md5()
        md5.update(filename)
        (name, ext) = os.path.splitext(filename)
        path = os.path.join(dirpath, filename)
        identifier = md5.hexdigest()
        self.index[identifier] = {'id': identifier, 'name': name, 'path': path}

  def items(self):
    return map(lambda x: x[1], self.index.items())

  def item(self, identifier):
    return self.index[identifier];

  def ids(self):
    return map(lambda x: x[0], self.index.items())


def application(environ, start_response):

  index = Index(directory)

  path = wsgiref.util.shift_path_info(environ)
  if (path == ""):

    response_body = json.dumps(index.items())
    status = '200 OK'
    headers = [('Content-Type', 'application/json'),
               ('Content-Length', str(len(response_body)))]
    start_response(status, headers)
    return [response_body]

  else:

    item = index.item(path)
    filepath = os.path.join(directory, item['path'])
    status = '200 OK'
    headers = [('Content-Type', 'image/jpeg'),
               ('Content-Length', str(os.path.getsize(filepath)))]
    start_response(status, headers)
    return open(filepath, "rb").read()


def main():

  parser = argparse.ArgumentParser(description = "Run a small web service exposing all the files within the specified directory.")
  parser.add_argument("directory", help = "Directory to index")
  options = parser.parse_args()

  global directory
  directory = options.directory

  httpd = wsgiref.simple_server.make_server(
    '0.0.0.0',
    8051,
    application
    )

  httpd.serve_forever()


if __name__ == '__main__':
  main()
