#ifndef CALIPER_OCCT_FACADE_H
#define CALIPER_OCCT_FACADE_H
#include <stdint.h>
#include <stdbool.h>

// Flat C interface over OCCT. The .mm implementation is the ONLY place OCCT's
// C++ headers are included, so C++ never reaches Swift. Handles are opaque
// uint64 tokens matching Caliper's SolidID.raw.
//
// Every function reports success via `bool` and writes results through out-params,
// so the Swift side can translate failures into KernelError without exceptions
// crossing the language boundary.

#ifdef __cplusplus
extern "C" {
#endif

typedef uint64_t caliper_solid_t;

bool caliper_occt_make_box(double sx, double sy, double sz,
                           double ox, double oy, double oz,
                           caliper_solid_t *out_id);

// Returns a flat triangle buffer the caller must free with caliper_occt_free_mesh.
typedef struct {
    float   *positions;   // xyz * vertex_count
    float   *normals;     // xyz * vertex_count
    uint32_t *indices;    // index_count
    uint32_t vertex_count;
    uint32_t index_count;
} caliper_mesh_t;

bool caliper_occt_tessellate(caliper_solid_t id, double tolerance, caliper_mesh_t *out_mesh);
void caliper_occt_free_mesh(caliper_mesh_t *mesh);

#ifdef __cplusplus
}
#endif
#endif
