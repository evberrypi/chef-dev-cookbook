name 'dev'
maintainer 'Everett lacey'
maintainer_email 'hello@everettlacey.com'
license 'All Rights Reserved'
description 'Installs/Configures dev'
long_description 'Installs/Configures dev'
version '0.1.003'
chef_version '>= 13.0'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/dev2/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/dev2'
depends 'ssh_keygen'
depends 'habitat'
