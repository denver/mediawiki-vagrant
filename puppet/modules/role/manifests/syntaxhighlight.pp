# == Class: role::syntaxhighlight
# Configures SyntaxHighlight extension
class role::syntaxhighlight {
    $extension = 'SyntaxHighlight_GeSHi'
    mediawiki::extension { $extension:
        composer => true,
    }

    file { 'pygmentize':
        path => "${mediawiki::dir}/extensions/${extension}/pygments/pygmentize",
        mode => 'a+x',
    }
}
