## TarballKit Framework

TarballKit is a swift framework for reading and writing [tarballs](https://en.wikipedia.org/wiki/Tar_(computing)) in iOS apps.

It is based on the [libarchive](https://github.com/libarchive/libarchive) library.

## Installation and Setup
TarballKit supports [Carthage](https://github.com/Carthage/Carthage).

### Carthage
`github "kolyvan/tarballkit"`

## Usage

### Reader
```swift
let reader = TarballReader(filePath: "/path/to/archive.tar")
for entry in reader {
  doSomething(entry.content)
}

let data = try reader.read(path: "entry.txt")
```

### Writer
```swift
let writer = try TarballWriter(filePath: "/path/to/archive.tar")
try writer.write(data: data, path: "entry.txt")
```

### License
TarballKit is open source and covered by a standard 2-clause BSD license. See the LICENSE file for more info.
