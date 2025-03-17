project(
  'docklet-picky',
  'vala',
  'c',
  version: '0.1.0',
)

# Dependencies
gtk_dep = dependency('gtk+-3.0')
plank_dep = dependency('plank')
math_dep = meson.get_compiler('c').find_library('m', required: true)

# Generate resource file
gnome = import('gnome')
resources = gnome.compile_resources('resources', 'picky.gresource.xml', source_dir: '.', c_name: 'resources')

# Source files
sources = [
  'PickyDocklet.vala',
  'PickyDockItem.vala',
  'PickyPreferences.vala',
  'PickerWindow.vala',
  'Color.vala',
  'ColorPreview.vala',
  resources,
]

# Build the shared library
shared_library(
  'docklet-picky',
  sources,
  dependencies: [gtk_dep, plank_dep, math_dep],
  install: true,
  install_dir: join_paths(get_option('libdir'), 'plank/docklets'),
  name_prefix: 'lib', # To ensure the output is libdocklet-picky.so
)
