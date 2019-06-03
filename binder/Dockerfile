# Note that there must be a tag
FROM pangeo/pangeo-notebook-onbuild:2019.05.23

CMD wget http://rtwilson.com/downloads/6SV-1.1.tar

CMD tar xvf 6SV-1.1.tar

CMD cd 6SV-1.1 && sed -i s/g77 $(FFLAGS)/gfortran -std=legacy -ffixed-line-length-none -ffpe-summary=none $(FFLAGS)/g Makefile && make && ln sixsV1.1 /usr/local/bin/sixs
