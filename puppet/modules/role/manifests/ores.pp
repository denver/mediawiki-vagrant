# == Class: role::ores
#
# Install the MediaWiki ORES extension and configure in test data mode.
# (To install the ORES service, use the ores_service role instead.)
#
class role::ores {
    include ::mysql

    mediawiki::extension { 'ORES':
        needs_update => true,
        settings     => {
            wgOresBaseUrl => 'https://ores.wikimedia.org/',

            # Point at some fake data with flat probability distribution.
            wgOresWikiId  => 'testwiki',
            wgOresModels  => {
                damaging     => {
                    enabled => true,
                },
                goodfaith    => {
                    enabled => true,
                },
                reverted     => {
                    enabled => false,
                },
                wp10         => {
                    enabled => false,
                },
                draftquality => {
                    enabled => false,
                },
            },
        },
    }
}
