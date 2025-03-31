project(
  'docklet-picky',
  'vala',
  'c',
  version: '0.1.1',
)

# Dependencies
gtk_dep = dependency('gtk+-3.0')
plank_dep = dependency('plank')
math_dep = meson.get_compiler('c').find_library('m', required: true)
i18n = import('i18n')

# Configure the build
customconf = configuration_data()
customconf.set('GETTEXT_PACKAGE', meson.project_name())

# Generate resource file
gnome = import('gnome')
resources = gnome.compile_resources('resources', 'picky.gresource.xml', source_dir: '.', c_name: 'resources')

add_project_arguments(
  [
    '-Wno-discarded-qualifiers',
    '-Wno-incompatible-pointer-types',
    '-Wno-unused',
    '-Wl,--enable-new-dtags',

    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  ],
  language: 'c',
)

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

# Build the shared module
shared_module(
  'docklet-picky',
  sources,
  dependencies: [gtk_dep, plank_dep, math_dep],
  install: true,
  install_dir: join_paths(get_option('libdir'), 'plank/docklets'),
)

subdir('po')
