module Scene exposing (..)

import Color exposing (Color)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2, vec2)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import WebGL exposing (Mesh, Shader)
import WebGL.Texture exposing  (Texture)


viewportWidthHeightRatio =
    16.0 / 9.0


type alias Uniforms =
    { rotation : Mat4
    , perspective : Mat4
    , camera : Mat4
    , shade : Float
    , texture : Texture
    }


uniforms : Float -> Texture -> Uniforms
uniforms theta texture =
    { rotation =
        Mat4.mul
            (Mat4.makeRotate (3 * theta) (vec3 0 1 0))
            (Mat4.makeRotate (2 * theta) (vec3 1 0 0))
    , perspective = Mat4.makePerspective 45 viewportWidthHeightRatio 0.01 100
    , camera = Mat4.makeLookAt (vec3 0 0 5) (vec3 0 0 0) (vec3 0 1 0)
    , shade = 1
    , texture = texture
    }



-- Mesh


type alias Vertex =
    { color : Vec3
    , position : Vec3
    }


cubeMesh : Mesh Vertex
cubeMesh =
    let
        rft =
            vec3 1 1 1

        lft =
            vec3 -1 1 1

        lbt =
            vec3 -1 -1 1

        rbt =
            vec3 1 -1 1

        rbb =
            vec3 1 -1 -1

        rfb =
            vec3 1 1 -1

        lfb =
            vec3 -1 1 -1

        lbb =
            vec3 -1 -1 -1
    in
        [ face Color.green rft rfb rbb rbt
        , face Color.blue rft rfb lfb lft
        , face Color.yellow rft lft lbt rbt
        , face Color.red rfb lfb lbb rbb
        , face Color.purple lft lfb lbb lbt
        , face Color.orange rbt rbb lbb lbt
        ]
            |> List.concat
            |> WebGL.triangles


face : Color -> Vec3 -> Vec3 -> Vec3 -> Vec3 -> List ( Vertex, Vertex, Vertex )
face rawColor a b c d =
    let
        color =
            let
                c =
                    Color.toRgb rawColor
            in
                vec3
                    (toFloat c.red / 255)
                    (toFloat c.green / 255)
                    (toFloat c.blue / 255)

        vertex position =
            Vertex color position
    in
        [ ( vertex a, vertex b, vertex c )
        , ( vertex c, vertex d, vertex a )
        ]



-- Shaders


vertexShader : Shader Vertex Uniforms { vcolor : Vec3, vcoord : Vec2 }
vertexShader =
    [glsl|

        attribute vec3 position;
        attribute vec3 color;

        uniform mat4 perspective;
        uniform mat4 camera;
        uniform mat4 rotation;

        varying vec3 vcolor;
        varying vec2 vcoord;

        void main () {
            gl_Position = perspective * camera * rotation * vec4(position, 1.0);
            vcolor = color;
            vcoord = position.xy;
        }

    |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3, vcoord : Vec2 }
fragmentShader =
    [glsl|

        precision mediump float;
        uniform float shade;
        uniform sampler2D texture;
        varying vec3 vcolor;
        varying vec2 vcoord;
        void main () {
            //gl_FragColor = shade * vec4(vcolor, 1.0);
            gl_FragColor = texture2D(texture, vcoord);
        }

    |]


entities : Texture -> Float -> List WebGL.Entity
entities texture time =
    let
        theta =
            time / 5000
    in
        [ WebGL.entity
            vertexShader
            fragmentShader
            cubeMesh
            (uniforms theta texture)
        ]
