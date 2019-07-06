# Caster

Playing around with [ray marching](http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/), [signed distance functions](https://en.wikipedia.org/wiki/Signed_distance_function), and WebGL.

![basic](img/screenshot.png)

## Format

    # 1 = box
    # 2 = sphere
    # 3 = capsule
    # 4 = cylinder
    # 5 = torus
    # 6 = ground
    # 99 = light
    # 100 = min (draw, noop, etc)
    # 101 = opUnion
    # 102 = opSubtraction
    # 103 = opIntersection
    # 104 = opSmoothUnion
    # 105 = opSmoothSubtraction
    # 106 = opSmoothIntersection
    #t,       p3              x4      
    [1,   -3.5, 1, 6.,    .5, 1., 1, .0]
    #m        op              c4
    [100, 0., 0., 0.,    0., 1., 0., 1.]
    
    #t,       p3              x4      
    [3,   3., .5, 6.,     .5, 1, 1, .0 ]
    [2,   3., 2., 6.,     .5, 1, 1, .0 ]
    #m      op               c4
    [104, .3, 0., 0.,    0., 1., 0., 1.]
    
    #l       p3              c4
    [99, 0., 3.5, 7.,    .5, .5, .2, 1.]
