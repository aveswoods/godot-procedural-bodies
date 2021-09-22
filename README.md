## Procedural Bodies in the Godot Game Engine

Implementation and explanation of how to create meshes and collision shapes by rotating a function around the y-axis. 

![Sample photo 2](https://github.com/azbeaver/godot-procedural-bodies/blob/main/images/sample2.png)

## About

An `EditorScript` tool that generates a `RigidBody` with a `MeshInstance` and a `CollisionShape` as children and saves it as a scene to the resources path.
The function that generates these nodes is a modified version of the example code found on [Using the ArrayMesh](https://docs.godotengine.org/en/stable/tutorials/content/procedural_geometry/arraymesh.html).

## Installing

I recommend directly downloading `make_procedural_body.gd` and adding it your project. The rest of this repository is dedicated to explaining how to use the function and how it works.

## Using

The script is an `EditorScript`, so you can run it directly through the editor. Doing so creates a file found at `res://body.scn`. The body is centered at (0, 0, 0). To change the body that is generated,
edit the parameters of the call to `get_new_body` in the `_run` function directly.

### Parameters

- `radius_function`:

   The function that is rotated around the y-axis is called `_radius_func`, and this is the value passed as `radius_function`. Evaluations of this function are translated into distances from the y-axis. There are important characteristics of this function:
   
   1. It is evaluated *only* over [0, 1], i.e., between 0 and 1 inclusive
   2. Its range over [0, 1] should also be [0, 1]. It does not *have* to be, but it is recommended
   3. It does *not* have to be continuous, but there ***cannot*** be any "holes" in the function
   4. It is passed as a `FuncRef` that takes one `float` input and returns one `float`

- `scale`:

   The amount to scale each axis. Treat as the bounding dimensions of the body. Default is `(1.0, 1.0, 1.0)`.

- `rings`:

   Number of evenly-spaced evaluations of the radius function, placed evenly along the y-axis. For example, if there are 3 rings, the radius function is evaluated at 0.0, 0.5, and 1.0.
   The distance from the y-axis at y = 0.0 is the value of the radius function evaluated at 0.0 (and likewise for the other two values). Default is 9 rings.
   *There should not be less than 3 rings.*

- `segments`:

   Number of evenly-spaced points around a ring. For example, if there are 3 segments, the body will look like a triangle when viewed from directly above.
   Default is 9 segments. *There **cannot** be less than 3 segments.*

Currently, there is no validation of the parameters. *Make sure your inputs are valid!*

### Explanation

There is a step-by-step explanation of how this implementation works in the in-line comments. This includes helpful links and higher-level interpretations. I recommend reading (or skimming) [Using the ArrayMesh](https://docs.godotengine.org/en/stable/tutorials/content/procedural_geometry/arraymesh.html)
first since the core implementation is the same as the sphere example.

If you'd change any wording of the comments, feel free to make a pull request!

## Sample Photos

### 1.

![Sample photo 1](https://github.com/azbeaver/godot-procedural-bodies/blob/main/images/sample1.png)

**Radius function:**
```
if x < 0.5:
  return x
else:
  return 1 - x
```
**Scale:** `(1.0, 1.0, 1.0)`

**Rings:** `3`

**Segments:** `3`

### 2.

![Sample photo 2](https://github.com/azbeaver/godot-procedural-bodies/blob/main/images/sample2.png)

**Radius function:**
```
return sin(0.7 * PI * x)
```
**Scale:** `(1.0, 2.0, 1.0)`

**Rings:** `50`

**Segments:** `50`

3.

![Sample photo 3](https://github.com/azbeaver/godot-procedural-bodies/blob/main/images/sample3.png)

(Notice that the collision shape is not concave. This is because all collision shapes are *convex*, so the closest convex shape is approximated.)

**Radius function:**
```
return (0.5 + 0.25 * cos(2 * PI * x))
```
**Scale:** `(0.8, 2.0, 0.8)`

**Rings**: `5`

**Segments:** `5`
