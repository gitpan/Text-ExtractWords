#
# ExtractWords.xs
# Last Modification: Wed Mar 19 12:10:26 WET 2003
#
# Copyright (c) 2003 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Text::ExtractWords;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(&words_count &words_list);
$VERSION = '0.01';

bootstrap Text::ExtractWords $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Text::ExtractWords - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Text::ExtractWords;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Text::ExtractWords was created by h2xs. It looks 
like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

Henrique Dias <hdias@esb.ucp.pt>

=head1 SEE ALSO

perl(1).

=cut
