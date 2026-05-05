import simplifile

pub type InertiaError {
  FileError(simplifile.FileError)
  TemplateNotFound
  ManifestNotFound
  ParseError
}
