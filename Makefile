
GENVER=600
BASE=$(PWD)
DB=
#SCH=etc/$(DB).sch
#export DBNAME=$(BASE)/etc/$(DB).db
export DBTYPE=sqt

FGLCOMP=fglcomp -r --make -M -W all -o bin$(GENVER)
FGLFORM=fglform -M -W all -o bin$(GENVER)
DEPLOYCMD=$(FGLASDIR)/bin/gasadmin gar  -E res.appdata.path=/opt/fourjs/gas$(GENVER)_appdata

.SUFFIXES: .4gl .42m .per .42f

bin$(GENVER)/%.42m: %.4gl
	$(FGLCOMP) $<

bin$(GENVER)/%.42f: %.per
	$(FGLFORM) $<

export FGLLDPATH=$(BASE)/bin$(GENVER):$(BASE)/.fglpkg/webcomponents
export FGLIMAGEPATH=$(BASE)/pics:$(BASE)/.fglpkg:$(BASE)/.fglpkg/webcomponents
export FGLDBPATH=$(BASE)/etc
export FGLRESOURCEPATH=$(BASE)/etc:$(BASE)/bin$(GENVER)

PROG=myapp
#FORMS=bin$(GENVER)/myform.42f
DESC=MyApp
XCF=$(PROG).xcf
PKGFGL=
PKGWC=
#PKGDIR=.fglpkg/webcomponents/
#PKGSRC=.fglpkg/webcomponents/$(PKGFGL)
DIST=distbin

all: bin$(GENVER) $(PKGSRC) $(SCH) $(FORMS) bin$(GENVER)/$(PROG).42m

#.fglpkg/webcomponents/$(PKGWC)
#	fglpkg install $(PKGWC)@1.1.1

etc/$(DB).sch: 
	cd etc && fgldbsch -db $(DB).db  -dv dbm$(DBTYPE) -of $(DB)

bin$(GENVER):
	mkdir bin$(GENVER)

etc:
	mkdir etc

run: $(FORMS) bin$(GENVER)/$(PROG).42m
	fglrun bin$(GENVER)/$(PROG).42m

clean:
	find . -name \*.42? -delete;
	rm -rf $(DIST) $(PROG).gar

etc/MANIFEST: etc
	@printf '%s\n' \
		'<MANIFEST>' \
		'    <DESCRIPTION>$(DESC)</DESCRIPTION>' \
		'    <APPLICATION xcf="$(XCF)"/>' \
		'</MANIFEST>' > $@
	@echo "Generated $@"

etc/$(XCF):
	@printf '%s\n' \
		'<APPLICATION Parent="defaultgwc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.4js.com/ns/gas/4.01/cfextwa.xsd">' \
		'    <EXECUTION>' \
		'        <ENVIRONMENT_VARIABLE Id="FGLRESOURCEPATH">.</ENVIRONMENT_VARIABLE>' \
		'        <ENVIRONMENT_VARIABLE Id="FGLIMAGEPATH">.</ENVIRONMENT_VARIABLE>' \
		'        <ENVIRONMENT_VARIABLE Id="FGLLDPATH">bin$(GENVER):.</ENVIRONMENT_VARIABLE>' \
		'        <ENVIRONMENT_VARIABLE Id="DBTYPE">sqt</ENVIRONMENT_VARIABLE>' \
		'        <ENVIRONMENT_VARIABLE Id="DBNAME">$(DB).db</ENVIRONMENT_VARIABLE>' \
		'        <PATH>$$(res.deployment.path)</PATH>' \
		'        <MODULE>bin$(GENVER)/$(PROG).42m</MODULE>' \
		'    </EXECUTION>' \
		'</APPLICATION>' > $@
	@echo "Generated $@"

# stage everything the archive needs into $(DIST) with MANIFEST + .xcf at the
# root, then zip from inside $(DIST) so the archive paths are relative to it.
$(PROG).gar: bin$(GENVER)/$(PROG).42m etc/MANIFEST etc/$(XCF)
	@rm -rf $(DIST) $(PROG).gar
	mkdir -p $(DIST)/webcomponents/$(PKGWC)
	cp etc/MANIFEST etc/$(XCF) $(DBNAME) $(DIST)/
	cp -r bin$(GENVER) $(DIST)/
#	cp -r $(PKGDIR)$(PKGWC) $(DIST)/webcomponents/
	cd $(DIST) && zip -r ../$(PROG).gar .

gar: $(PROG).gar

deploy: $(PROG).gar
	-$(DEPLOYCMD) --disable-archive $(PROG) && $(DEPLOYCMD) --undeploy-archive $(PROG)
	$(DEPLOYCMD) --deploy-archive $(PROG).gar
	$(DEPLOYCMD) --enable-archive $(PROG)
