/*
 * ExtractWords.xs
 * Last Modification: Wed Mar 19 12:10:42 WET 2003
 *
 * Copyright (c) 2003 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
 * This module is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 */

#ifdef OP_PROTOTYPE
#undef OP_PROTOTYPE
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <locale.h>
#include <string.h>

#define PERL_POLLUTE

#ifdef HAVE_LOCALE_H
	setlocale(LC_CTYPE,"pt_PT.ISO_8859-1");
	setlocale(LC_COLLATE,"pt_PT.ISO_8859-1");
	setlocale(LC_MESSAGES,"");
#endif

#define MINWORDLEN 2
#define MAXWORDLEN 32

char delimiters[] = " _,.!?;:|\\/@\t\b\f\n\r&=\"()<>{}[]+*~^`";
char hexchars[] = "0123456789abcdef";

void unescape_str(unsigned char *s) {
	register int x,y;
	for(x=0, y=0; s[y]; ++x, ++y) {
		if((s[x] = s[y]) == '%') {
			int hex;
			if(strchr(hexchars, toLOWER(s[y+1])) &&
				strchr(hexchars, toLOWER(s[y+2])) &&
					sscanf(&s[y+1], "%02X", &hex)) {
				s[x] = hex;
				y+=2;
			} else if(x == 0 || (x > 0 && !isDIGIT(s[x-1]))) s[x] = ' ';
		} else if(((s[x] = s[y]) == '#' && !strchr(hexchars, toLOWER(s[y+1]))) ||
				((s[x] = s[y]) == '$' && !(isDIGIT(s[y+1]) || (y > 0 && isDIGIT(s[y-1])))))
			s[x] = ' ';
	}
	s[x] = '\0';
}

unsigned char *str_chr_uniq(unsigned char *s) {
	unsigned char *s0 = s;
	unsigned char *p;
	if(*s == '#') return s0;
	for(p = s; *p = *s; ++s)
		if(isDIGIT(*s) || (*s != *(s+1)) ||
			(isALPHA(*s) && *s == *(s+1) && *(s+1) != *(s+2) && *(s+2) != '\0')) ++p;
	return s0;
}

unsigned char *str_to_lower(unsigned char *string) {
	unsigned char *p = string;
	while(*p = tolower(*p)) *p++;
	return string;
}


MODULE = Text::ExtractWords	PACKAGE = Text::ExtractWords	PREFIX = ew_

PROTOTYPES: DISABLE

void
ew_words_list(aref, source)
		SV	*aref;
		char	*source;
	PREINIT:
		char *t = NULL;
		I32 n = 0;
	PPCODE:
		if(SvROK(aref) && SvTYPE(SvRV(aref)) == SVt_PVAV) {
			AV *av = (AV *)SvRV(aref);
			unsigned char *tmp = SvPV(newSVpvn(source, strlen(source)), PL_na);
			unescape_str(tmp);
			for(t = strtok(tmp, delimiters); t != NULL; t = strtok(NULL, delimiters)) {
				n = strlen(str_chr_uniq(t));
				if(n < MINWORDLEN) continue;
				t = t + n - 1;
				while(*t == '\'' || *t == '-' || *t == '#') { *t = '\0'; --t; --n; }
				t = t - n + 1;
				while(*t == '\'' || *t == '-' || (*t == '#' && *(t+1) == '#')) { ++t; --n; }
				if(n >= MINWORDLEN && n <= MAXWORDLEN) {
					str_to_lower(t);
					av_push(av, newSVpv(t, n));
				}
			}
			Safefree(tmp);
		} else
			croak("not array ref passed to Text::ExtractWords::words_list");



void
ew_words_count(href, source)
		SV	*href;
		char	*source;
	PREINIT:
		char *t = NULL;
		I32 n = 0;
		unsigned long count;
	PPCODE:
		if(SvROK(href) && SvTYPE(SvRV(href)) == SVt_PVHV) {
			HV *hv = (HV *)SvRV(href);
			unsigned char *tmp = SvPV(newSVpvn(source, strlen(source)), PL_na);
			unescape_str(tmp);
			for(t = strtok(tmp, delimiters); t != NULL; t = strtok(NULL, delimiters)) {
				n = strlen(str_chr_uniq(t));
				if(n < MINWORDLEN) continue;
				t = t + n - 1;
				while(*t == '\'' || *t == '-' || *t == '#') { *t = '\0'; --t; --n; }
				t = t - n + 1;
				while(*t == '\'' || *t == '-' || (*t == '#' && *(t+1) == '#')) { ++t; --n; }
				if(n >= MINWORDLEN && n <= MAXWORDLEN) {
					str_to_lower(t);
					count = 1;
					if(hv_exists(hv, t, n)) {
						SV **svalue = hv_fetch(hv, t, n, 0);
						count = SvIV(*svalue) + 1;
					}
					hv_store(hv, t, n, newSViv(count), 0);
				}
			}
			Safefree(tmp);
		} else
			croak("not hash ref passed to Text::ExtractWords::words_count");
