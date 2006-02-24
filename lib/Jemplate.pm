package Jemplate;
use 5.006001;
use strict;
use warnings;
use Template 2.14;

our $VERSION = '0.14';

use Jemplate::Parser;

sub compile_module {
    my ($class, $module_path, $template_file_paths) = @_;
    my $result = $class->compile_template_files(@$template_file_paths)
      or return;
    open MODULE, "> $module_path"
        or die "Can't open '$module_path' for output:\n$!";
    print MODULE $result;
    close MODULE;
    return 1;
}

sub compile_module_cached {
    my ($class, $module_path, $template_file_paths) = @_;
    my $m = -M $module_path;
    return 0 unless grep { -M($_) < $m } @$template_file_paths;
    return $class->compile_module($module_path, $template_file_paths); 
}

sub compile_template_files {
    my $class = shift;
    my $output = $class->_preamble;
    for my $filepath (@_) {
        my $filename = $filepath;
        $filename =~ s/.*[\/\\]//;
        open FILE, $filepath
          or die "Can't open '$filepath' for input:\n$!";
        my $template_input = do {local $/; <FILE>};
        close FILE;
        $output .= 
            $class->compile_template_content($template_input, $filename);
    }
    return $output;
}

sub compile_template_content {
    die "Invalid arguments in call to Jemplate->compile_template_content"
      unless @_ == 3;
    my ($class, $template_content, $template_name) = @_;
    my $parser = Jemplate::Parser->new;
    my $parse_tree = $parser->parse(
        $template_content, {name => $template_name}
    ) or die $parser->error;
    my $output =
        "Jemplate.templateMap['$template_name'] = " .
        $parse_tree->{BLOCK} .
        "\n";
    for my $function_name (sort keys %{$parse_tree->{DEFBLOCKS}}) {
        $output .= 
            "Jemplate.templateMap['$function_name'] = " .
            $parse_tree->{DEFBLOCKS}{$function_name} .
            "\n";
    }
    return $output;
}

sub _preamble {
    return <<'...';
/* 
   This Javascript code was generated by Jemplate, the Javascript
   Template Toolkit. Any changes made to this file will be lost the next
   time the templates are compiled.

   Copyright 2006 - Ingy döt Net - All rights reserved.
*/

if (typeof(Jemplate) == 'undefined')
    throw('Jemplate.js must be loaded before any Jemplate template files');

...
}

1;

=head1 NAME

Jemplate - Javascript Templating with Template Toolkit

=head1 SYNOPSIS

    var data = fetchSomeJsonResult();
    var elem = document.getElementById('some-div');
    elem.innerHTML = Jemplate.process('my-template.html', data);

or

    Jemplate.process('my-template.html', fetchSomeJsonResult(), '#some-div');

or, with Prototype.js:

    new Ajax.Request("/json", {
        onComplete: function(req) {
            var data = eval(req.responseText);
            Jemplate.process('my-template.html', data, '#some-div');
        }
    );

=head1 DESCRIPTION

Jemplate is a templating framework for Javascript that is built over
Perl's Template Toolkit (TT2).

Jemplate parses TT2 templates using the TT2 Perl framework, but with a
twist. Instead of compiling the templates into Perl code, it compiles
them into Javascript.

Jemplate then provides a Javascript runtime module for processing
the template code. Presto, we have full featured Javascript
templating language!

Combined with JSON and xmlHttpRequest, Jemplate provides a really simple
and powerful way to do Ajax stuff.

=head1 HOWTO

Jemplate comes with a command line tool call C<jemplate> that you use to
precompile your templates into javscript. For example if you have a
template directory called C<templates> that contains:

    > ls templates/
    body.html
    footer.html
    header.html

You might run this command:

    > jemplate --compile template/* > js/jemplate01.js

This will compile all the templates into one Javascript file.

You also need to get the Jemplate runtime.

    > cp ~/Jemplate-x.xx/share/Jemplate.js js/Jemplate.js

Now all you need to do is include these two files in the HEAD of
your html:

    <script src="js/Jemplate.js" type="text/javascript"></script>
    <script src="js/jemplate01.js" type="text/javascript"></script>

Now you have Jemplate support for these templates in your html document.

=head1 PUBLIC API

The Jemplate.pm module has the following public class methods:

=over

=item Jemplate->compile_template_files(@template_file_paths);

Take a list of template file paths and compile them into a module of
functions. Returns the text of the module.

=item Jemplate->compile_template_content($content, $template_name);

Compile one template whose content is in memory. You must provide a
unique template name. Returns the Javascript text result of the
compilation.

=item Jemplate->compile_module($module_path, \@template_file_paths);

Similar to `compile_template_files`, but prints to result to the
$module_path. Returns 1 if successful, undef if error.

=item Jemplate->compile_module_cached($module_path, \@template_file_paths);

Similar to `compile_module`, but only compiles if one of the templates
is newer than the module. Returns 1 if sucessful compile, 0 if no
compile due to cache, undef if error.

=back

=head1 CURRENT SUPPORT

The goal of Jemplate is to support all of the Template Toolkit features
that can possibly be supported.

Jemplate now supports the following directives:

  * Plain text
  * [% [GET] variable %]
  * [% CALL variable %]
  * [% [SET] variable = value %]
  * [% INCLUDE [arguments] %]
  * [% PROCESS [arguments] %]
  * [% BLOCK name %]
  * [% WRAPPER template [variable = value ...] %]
  * [% IF condition %]
  * [% ELSIF condition %]
  * [% ELSE %]
  * [% SWITCH variable %]
  * [% CASE [{value|DEFAULT}] %]
  * [% FOR x = y %]
  * [% WHILE expression %]
  * [% RETURN %]
  * [% STOP %]
  * [% NEXT %]
  * [% LAST %]
  * [% CLEAR %]
  * [%# this is a comment %]

All the array virtual functions are supported:

  * first           first item in list
  * grep(re)        items matching re
  * join(str)       items joined with str
  * last            last item in list
  * max             maximum index number (i.e. size - 1)
  * merge(list [, list...])     combine lists
  * nsort           items sorted numerically
  * pop             remove first item from list
  * push(item)      add item to end of list
  * reverse         items in reverse order
  * shift           remove last item from list
  * size            number of elements
  * slice(from, to)     subset of list
  * sort            items sorted lexically
  * splice(off, len [,list])    modifies list
  * unique          unique items (retains order)
  * unshift(item)   add item to start of list

None of the hash virtual functions are supported yet. Very soon.

None of the string virtual functions are supported yet. Very soon.

The remaining features will be added very soon. See the DESIGN document
in the distro for a list of all features and their progress.

=head1 DEVELOPMENT

The bleeding edge code is available via Subversion at
http://svn.kwiki.org/ingy/Jemplate/

You can run the runtime tests directly from
http://svn.kwiki.org/ingy/Jemplate/tests or from the corresponding CPAN
or JSAN directories.

Jemplate development is being discussed at irc://irc.freenode.net/#jemplate

If you want a committer bit, just ask ingy on the irc channel.

=head1 CREDIT

This module is only possible because of Andy Wardley's mighty Template
Toolkit. Thanks Andy. I will gladly give you half of any beers I
receive for this work. (As long as you are in the same room when I'm
drinking them ;)

=head1 AUTHORS

Ingy döt Net <ingy@cpan.org>

* miyagawa
* yann
* David Davis <xantus@xantus.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
