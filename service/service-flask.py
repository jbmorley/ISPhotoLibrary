#!/usr/bin/env python

import argparse
import os
import json
import hashlib
import os.path
import mimetypes

directory = "/Users/jbmorley/Movies/TV Shows (Downloads)"

from flask import Flask, send_file
app = Flask(__name__)
index = None

class Index:

  def __init__(self, directory):
    self.directory = directory
    self.hashes = {}
    self.types = {}
    self.refresh()

  def initialize(self):
    self.index = {}
    self.listing = []

  def md5(self, string):
    try:
      return self.hashes[string]
    except:
      md5 = hashlib.md5()
      md5.update(string)
      self.hashes[string] = md5.hexdigest()
      return self.hashes[string]

  def mimetype(self, filename):
    try:
      return self.types[filename]
    except:
      (mimetype, encoding) = mimetypes.guess_type(filename)
      self.types[filename] = mimetype
      return mimetypes

  def refresh(self):
    self.initialize()
    for (dirpath, dirnames, filenames) in os.walk(self.directory):
      for filename in filenames:
        (name, ext) = os.path.splitext(filename)
        path = os.path.join(dirpath, filename)
        identifier = self.md5(filename)
        self.index[identifier] = path
        self.listing.append({'id': identifier, 'name': name, 'filename': filename, 'extension': ext, 'mimetype': self.mimetype(filename)})

  def items(self):
    self.refresh()
    return self.listing

  def item(self, identifier):
    return self.index[identifier];

  def ids(self):
    return map(lambda x: x[0], self.index.items())


index = Index(directory) 


@app.route("/")
def listing():
  return json.dumps(index.items())


@app.route("/<filename>")
def file(filename):
  item = index.item(filename)
  filepath = os.path.join(index.directory, item)
  return send_file(filepath)


if __name__ == "__main__":

  parser = argparse.ArgumentParser(description = "Run a small web service exposing all the files within the specified directory.")
  parser.add_argument("directory", help = "Directory to index")
  options = parser.parse_args() 

  index = Index(options.directory) 

  app.run(host='0.0.0.0')
