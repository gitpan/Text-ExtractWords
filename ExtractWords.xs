/*
 * ExtractWords.xs
 * Last Modification: Fri May 23 11:41:20 WEST 2003
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

char delimiters[] = "\xAB\xBB _,.!?;:|\\/@\t\b\f\n\r&=\"()<>{}[]+*~^`";
char xxxchar[] = " +-*:.|&;,_#%!";
char xxchar[] = "+-*:.|&;,_#%!";

void unescape_str(unsigned char *s) {
	register int x,y;
	for(x=0, y=0; s[y]; ++x, ++y) {
		if((s[x] = s[y]) == '%') {
			int hex;
			if(isxdigit(s[y+1]) && isxdigit(s[y+2]) &&
					sscanf(&s[y+1], "%02X", &hex)) {
				s[x] = hex;
				y+=2;
			} else if(x == 0 || (x > 0 && !isDIGIT(s[x-1]))) s[x] = ' ';
		} else if(((s[x] = s[y]) == '#' &&
				!(isxdigit(s[y+1]) &&
				isxdigit(s[y+2]) &&
				isxdigit(s[y+3]) &&
				isxdigit(s[y+4]) &&
				isxdigit(s[y+5]) &&
				isxdigit(s[y+6]) &&
				!isalnum(s[y+7]) &&
				(y == 0 || !isalnum(s[y-1])))) ||
				((s[x] = s[y]) == '$' && !(isDIGIT(s[y+1]) || (y > 0 && isDIGIT(s[y-1])))))
			s[x] = ' ';
		else if(y > 4 && s[y] == '-' && isalpha(s[y-1]) &&
			isalpha(s[y-2]) && isalpha(s[y-3]) && isalpha(s[y-4]) &&
				isalpha(s[y-5]) && isalpha(s[y+1]) && isalpha(s[y+2]) && isalpha(s[y+3]) &&
					isalpha(s[y+4]) && isalpha(s[y+5]))
			s[x] = ' ';
	}
	s[x] = '\0';
}

unsigned char *str_scan(unsigned char *t, unsigned char *s, unsigned long *slen) {
	unsigned char *p = t;

	*slen = 0;
	while(*s && !isalnum(*s)) s++;
	while(*s) {
		if(*(s+1) && strchr(xxxchar, *(s-1)) &&
			isalnum(*s) && strchr(xxxchar, *(s+1)) &&
				!(*(s-1) == '.' && *(s+1) == '.' && isDIGIT(*s) && *s != '0') &&
					!(*(s-1) == ' ' && *(s+1) == ' ' && isalnum(*(s+2)) && isalnum(*(s+3)))) {
			*t = tolower(*s);
			if(*(s+1) && *(s+2) && *(s+3) &&
				strchr(xxchar, *(s+1)) &&
					strchr(xxchar, *(s+2)) &&
						!strchr(xxchar, *(s+3))) s++;
			if(*s && *(s+1) && (*(s+1) != ' ' || (*(s-1) == ' ' && *(s+1) == ' '))) s++;
		} else if(*s == '@' &&
				*(s-1) != 'a' && *(s-1) != 'A' && isalpha(*(s-1)) &&
				*(s+1) != 'a' && *(s+1) != 'A' && isalpha(*(s+1))) {
			unsigned int i = 2;
			while(*(s+i) && isalpha(*(s+i))) i++;
			*t = (*(s+i) == '.' && isalpha(*(s+i+1))) ? *s : 'a';
		} else if(*s == '$' &&
				*(s-1) != 's' && *(s-1) != 'S' && isalpha(*(s-1)) &&
				*(s+1) != 's' && *(s+1) != 'S' && isalpha(*(s+1))) {
			*t = 's';
		} else if(*(s+1) && strchr(xxchar, *s) && strchr(xxchar, *(s+1))) {
			*t = ' ';
			s++;
		} else *t = tolower(*s);
		if(*s) {
			s++;
			t++;
		}
	}
	*t = '\0';
	*slen = t - p;
	return p;
}

unsigned char *str_chr_uniq(unsigned char *s) {
	unsigned char *s0 = s;
	unsigned char *p;
	if(*s == '#') return s0;
	for(p = s; *p = *s; ++s)
		if(isDIGIT(*s) || (*s != *(s+1)) ||
			(isalpha(*s) && *s == *(s+1) && *(s+1) != *(s+2) && *(s+2) != '\0')) ++p;
	return s0;
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
			unsigned long ls;
			if(ls = strlen(source)) {
				AV *av = (AV *)SvRV(aref);
				unsigned char *tmp = NULL;
				New(0, tmp, (size_t)ls+1, unsigned char);
				str_scan(tmp, source, &ls);
				unescape_str(tmp);
				for(t = strtok(tmp, delimiters); t != NULL; t = strtok(NULL, delimiters)) {
					n = strlen(str_chr_uniq(t));
					if(n < MINWORDLEN) continue;
					t = t + n - 1;
					while(*t == '\'' || *t == '-' || *t == '#') { *t = '\0'; --t; --n; }
					t = t - n + 1;
					while(*t == '\'' || *t == '-' || (*t == '#' && *(t+1) == '#')) { ++t; --n; }
					if(n >= MINWORDLEN && n <= MAXWORDLEN)
						av_push(av, newSVpv(t, n));
				}
				if(tmp) Safefree(tmp);
			}
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
			unsigned long ls;
			if(ls = strlen(source)) {
				HV *hv = (HV *)SvRV(href);
				unsigned char *tmp = NULL;
				New(1, tmp, (size_t)ls+1, unsigned char);
				//fprintf(stdout, "%s\n", source);
				str_scan(tmp, source, &ls);
				//fprintf(stdout, "%s\n", tmp);
				unescape_str(tmp);
				for(t = strtok(tmp, delimiters); t != NULL; t = strtok(NULL, delimiters)) {
					n = strlen(str_chr_uniq(t));
					if(n < MINWORDLEN) continue;
					t = t + n - 1;
					while(*t == '\'' || *t == '-' || *t == '#') { *t = '\0'; --t; --n; }
					t = t - n + 1;
					while(*t == '\'' || *t == '-' || (*t == '#' && *(t+1) == '#')) { ++t; --n; }
					if(n >= MINWORDLEN && n <= MAXWORDLEN) {
						count = 1;
						if(hv_exists(hv, t, n)) {
							SV **svalue = hv_fetch(hv, t, n, 0);
							count = SvIV(*svalue) + 1;
						}
						hv_store(hv, t, n, newSViv(count), 0);
					}
				}
				if(tmp) Safefree(tmp);
			}
		} else
			croak("not hash ref passed to Text::ExtractWords::words_count");
