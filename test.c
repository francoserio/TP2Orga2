#include "rdtsc.h"
#include "solver.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#define REPETITIONS 750
#define REPETITIONSSOLVE 1000

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

int run_solver_lin_solver(){
	uint32_t b = 0;
	unsigned long start;
	unsigned long end;
	unsigned long delta;
	//unsigned int estado=0;

	FILE* output = fopen("solver_lin_solve.csv", "w+");

	fluid_solver* solver_pri = solver_create(sizes[3], 0.05, 0, 0);
	fluid_solver* solver_seg = solver_create(sizes[4], 0.05, 0, 0);
	fluid_solver* solver_ter = solver_create(sizes[5], 0.05, 0, 0);
	FILE* out_asm_128 = fopen("asm_128.csv", "a");
	FILE* out_c_128 = fopen("c_128.csv", "a");

	FILE* out_asm_256 = fopen("asm_256.csv", "a");
	FILE* out_c_256 = fopen("c_256.csv", "a");

	FILE* out_asm_512 = fopen("asm_512.csv", "a");
	FILE* out_c_512 = fopen("c_512.csv", "a");
	for (int i = 0; i < REPETITIONSSOLVE; i++){
		//c medida 128
		RDTSC_START(start);
		solver_lin_solve_c(solver_pri, b, solver_pri->dens, solver_pri->dens_prev, 0.5, 2);
		RDTSC_STOP(end);
		delta = end - start;
		fprintf(out_c_128, "%lu\n", delta);

		//asm medida 256
		RDTSC_START(start);
		solver_lin_solve_asm(solver_seg, b, solver_seg->dens, solver_seg->dens_prev, 2, 8);
		RDTSC_STOP(end);
		delta = end - start;
		fprintf(out_asm_256, "%lu\n", delta);

		//c medda 512
		RDTSC_START(start);
		solver_lin_solve_c(solver_ter, b, solver_ter->dens, solver_ter->dens_prev, 1, 4);
		RDTSC_STOP(end);
		delta = end - start;
		fprintf(out_c_512, "%lu\n", delta);

		//asm medida 128
		RDTSC_START(start);
		solver_lin_solve_asm(solver_pri, b, solver_pri->dens, solver_pri->dens_prev, 0.5, 2);
		RDTSC_STOP(end);
		delta = end - start;
		fprintf(out_asm_128, "%lu\n", delta);

		//c medida 256
		RDTSC_START(start);
		solver_lin_solve_c(solver_seg, b, solver_seg->dens, solver_seg->dens_prev, 2, 8);
		RDTSC_STOP(end);
		delta = end - start;
		fprintf(out_c_256, "%lu\n", delta);

		//asm medda 512
		RDTSC_START(start);
		solver_lin_solve_asm(solver_ter, b, solver_ter->dens, solver_ter->dens_prev, 1, 4);
		RDTSC_STOP(end);
		delta = end - start;
		printf("iteracion %i \n", i);
		fprintf(out_asm_512, "%lu\n", delta);
	}
	return 0;
}

int main() {
  run_solver_set_bnd();
  run_solver_lin_solver();
}
