#include "rdtsc.h"
#include "solver.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#define REPETITIONS 750

uint32_t sizes[6] = {16, 32, 64, 128, 256, 512};

int run_solver_set_bnd() {
  unsigned long start;
  unsigned long end;
  unsigned int codigo = 0;
  unsigned int matriz = 0;
  unsigned long delta;

  uint32_t b = 0;
  FILE* output = fopen("solver_set_bnd.csv", "w+");
  for (int j = 0; j < 6; j++) { //la cantidad de sizes
    fluid_solver* solver = solver_create(sizes[j], 0.05, 0, 0);
    for (int i = 0; i < REPETITIONS; i++) { //la cantidad de repeticiones
      if (b == 0) {
        b = 1;
      } else if (b == 1) {
        b = 2;
      } else {
        b = 0;
      }

      if (codigo == 1) {        //ASM
        if (matriz == 3) {
          RDTSC_START(start);
          solver_set_bnd_asm(solver, b, solver->v);
          RDTSC_STOP(end);
          delta = end - start;
          fprintf(output, "%d %d %d %lu %d\n", codigo, b, sizes[j], delta, matriz);
          matriz = 1;
        } else if (matriz == 4) {
          RDTSC_START(start);
          solver_set_bnd_asm(solver, b, solver->u);
          RDTSC_STOP(end);
          delta = end - start;
          fprintf(output, "%d %d %d %lu %d\n", codigo, b, sizes[j], delta, matriz);
          matriz = 0;
        }
        codigo = 0;
      } else {                    //C
        if (matriz == 0) {
          RDTSC_START(start);
          solver_set_bnd_c(solver, b, solver->v);
          RDTSC_STOP(end);
          delta = end - start;
          fprintf(output, "%d %d %d %lu %d\n", codigo, b, sizes[j], delta, matriz);
          matriz = 3;
        } else if (matriz == 1) {
          RDTSC_START(start);
          solver_set_bnd_c(solver, b, solver->u);
          RDTSC_STOP(end);
          delta = end - start;
          fprintf(output, "%d %d %d %lu %d\n", codigo, b, sizes[j], delta, matriz);
          matriz = 4;
        }
        codigo = 1;
      }
    }
  }
  fclose(output);
  return 0;
}

int main() {
  run_solver_set_bnd();
}
