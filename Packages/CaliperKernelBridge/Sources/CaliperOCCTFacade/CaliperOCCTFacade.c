#include "CaliperOCCTFacade.h"

// STUB. Real geometry lives in CaliperOCCTFacade.mm once OCCT.xcframework is added.
// Keeping this as .c with no OCCT include means the package builds on any machine.

bool caliper_occt_make_box(double sx, double sy, double sz,
                           double ox, double oy, double oz,
                           caliper_solid_t *out_id) {
    (void)sx;(void)sy;(void)sz;(void)ox;(void)oy;(void)oz;(void)out_id;
    return false; // not implemented — bridge falls back / throws
}

bool caliper_occt_tessellate(caliper_solid_t id, double tolerance, caliper_mesh_t *out_mesh) {
    (void)id;(void)tolerance;(void)out_mesh;
    return false;
}

void caliper_occt_free_mesh(caliper_mesh_t *mesh) { (void)mesh; }
