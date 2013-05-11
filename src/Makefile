TARGET = g2c
TEST_DIR = ../test

all: $(TARGET) test

g2c: ggram.cmi g.cmo ggram.cmo glex.cmo printc.cmo g2c.cmo
	ocamlc -o $@ g.cmo ggram.cmo glex.cmo printc.cmo g2c.cmo

test:
	./g2c $(TEST_DIR)/actual.g > $(TEST_DIR)/actual.c
	diff $(TEST_DIR)/actual.c $(TEST_DIR)/expect.c

depend:
	ocamldep *.ml *.mli > .depend

clean:
	rm -rf *.cmi *.cmo $(TARGET)
	rm -rf glex.ml glex.mli ggram.mli ggram.ml

.SUFFIXES: .ml .mli .mll .mly .cmo .cmi

.ml.cmo:
	ocamlc -c $<
.mli.cmi:
	ocamlc -c $<
.mll.ml:
	ocamllex $<
.mll.mli:
	ocamllex $<
.mly.ml:
	ocamlyacc $<
.mly.mli:
	ocamlyacc $<

include .depend
