use std::ops::Range;

use bevy::{
    pbr::wireframe::{WireframeConfig, WireframePlugin},
    prelude::*,
    render::{
        mesh::{Indices, VertexAttributeValues},
        render_resource::PrimitiveTopology,
    },
};
use rand::{self, Rng};

struct GeneratorSettings {
    side_length: usize,
    num_small_craters: usize,
    num_large_craters: usize,

    small_crater_radius: Range<f32>,
    small_crater_depth: f32,
    large_crater_radius: Range<f32>,
    large_crater_depth: f32,
}

impl Default for GeneratorSettings {
    fn default() -> Self {
        Self {
            side_length: 100,
            num_small_craters: 5,
            num_large_craters: 2,
            small_crater_radius: 2.0..5.0,
            small_crater_depth: 10.0,
            large_crater_radius: 10.0..20.0,
            large_crater_depth: 10.0,
        }
    }
}

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(WireframePlugin)
        .add_systems(Startup, setup)
        .add_systems(Update, (camera_controls, wireframe_controls))
        .insert_resource(WireframeConfig {
            global: false,
            default_color: Color::WHITE,
        })
        .run();
}

const LENGTH: usize = 100;

pub fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    let mut mesh = Mesh::new(PrimitiveTopology::TriangleList);

    let mut vertices: Vec<[f32; 3]> = Vec::new();
    let mut normals: Vec<[f32; 3]> = Vec::new();
    let mut indices: Vec<u32> = Vec::new();

    let vertex_count = LENGTH * LENGTH;

    vertices.resize(vertex_count, [0.0f32, 0.0f32, 0.0f32]);
    normals.resize(vertex_count, [0.0f32, 1.0f32, 0.0f32]);

    let sea_level = 0;

    struct Crater {
        x: f32,
        z: f32,
        radius: f32,
        depth: f32,
    }

    impl Crater {
        fn new<'a, 'b>(
            x: Range<usize>,
            z: Range<usize>,
            radius: Range<f32>,
            depth: f32,
            // mut rng: ThreadRng<'a>,
        ) -> Self {
            let mut rng = rand::thread_rng();
            Self {
                x: rng.gen_range(x) as f32,
                z: rng.gen_range(z) as f32,
                radius: rng.gen_range(radius),
                depth,
            }
        }
    }

    let craters = vec![
        // Large
        Crater::new(0..LENGTH, 0..LENGTH, 10.0..20.0, 10.0),
        Crater::new(0..LENGTH, 0..LENGTH, 10.0..20.0, 10.0),
        // Small
        Crater::new(0..LENGTH, 0..LENGTH, 2.0..5.0, 10.0),
        Crater::new(0..LENGTH, 0..LENGTH, 2.0..5.0, 10.0),
        Crater::new(0..LENGTH, 0..LENGTH, 2.0..5.0, 10.0),
        Crater::new(0..LENGTH, 0..LENGTH, 2.0..5.0, 10.0),
        Crater::new(0..LENGTH, 0..LENGTH, 2.0..5.0, 10.0),
    ];

    for x in 0..LENGTH {
        for z in 0..LENGTH {
            vertices[x * LENGTH + z] = [x as f32, sea_level as f32, z as f32];

            for Crater {
                x: cx,
                z: cz,
                radius,
                depth,
            } in &craters
            {
                let distance = ((x as f32 - *cx).powf(2.0) + (z as f32 - *cz).powf(2.0)).sqrt();
                if distance < *radius as f32 {
                    let height = (((distance + radius) * (distance - radius)) as f32) / depth;
                    vertices[x * LENGTH + z] =
                        [x as f32, height.min(vertices[x * LENGTH + z][1]), z as f32];
                }
            }
        }
    }

    for x in 0..LENGTH - 1 {
        for z in 0..LENGTH - 1 {
            let index = x * LENGTH + z;
            indices.push(index as u32);
            indices.push((index + 1) as u32);
            indices.push((index + LENGTH) as u32);

            indices.push((index + 1) as u32);
            indices.push((index + 1 + LENGTH) as u32);
            indices.push((index + LENGTH) as u32);
        }
    }

    mesh.insert_attribute(
        Mesh::ATTRIBUTE_POSITION,
        VertexAttributeValues::Float32x3(vertices),
    );
    mesh.insert_attribute(
        Mesh::ATTRIBUTE_NORMAL,
        VertexAttributeValues::Float32x3(normals),
    );
    mesh.set_indices(Some(Indices::U32(indices)));

    commands.spawn((PbrBundle {
        mesh: meshes.add(mesh),
        material: materials.add(Color::RED.into()),
        transform: Transform::from_xyz(0.0, 0.0, 0.0),
        ..default()
    },));

    // Transform for the camera and lighting, looking at (0,0,0) (the position of the mesh).
    let camera_and_light_transform =
        Transform::from_xyz(-1.8, 1.8, -1.8).looking_at(Vec3::ZERO, Vec3::Y);

    // Camera in 3D space.
    commands.spawn(Camera3dBundle {
        transform: camera_and_light_transform,
        ..default()
    });

    // Light up the scene.
    commands.spawn(PointLightBundle {
        point_light: PointLight {
            intensity: 1000.0,
            range: 1000.0,
            ..default()
        },
        transform: Transform::from_xyz(50.0, 10.0, 50.0),
        ..default()
    });
}

pub fn camera_controls(
    time: Res<Time>,
    keyboard_input: Res<Input<KeyCode>>,
    mut query: Query<&mut Transform, With<Camera>>,
) {
    let control = keyboard_input.any_pressed([KeyCode::ControlLeft, KeyCode::ControlRight]);
    if control {
        return;
    }

    let mut movement = Vec3::ZERO;
    if keyboard_input.pressed(KeyCode::W) {
        movement += Vec3::Z;
    }
    if keyboard_input.pressed(KeyCode::S) {
        movement -= Vec3::Z;
    }
    if keyboard_input.pressed(KeyCode::A) {
        movement -= Vec3::X;
    }
    if keyboard_input.pressed(KeyCode::D) {
        movement += Vec3::X;
    }
    if keyboard_input.pressed(KeyCode::Q) {
        movement -= Vec3::Y;
    }
    if keyboard_input.pressed(KeyCode::E) {
        movement += Vec3::Y;
    }

    let mut query = query.single_mut();
    query.translation += movement * time.delta_seconds() * 10.0;
}

pub fn wireframe_controls(
    mut wireframe: ResMut<WireframeConfig>,
    keyboard_input: Res<Input<KeyCode>>,
) {
    let control = keyboard_input.any_pressed([KeyCode::ControlLeft, KeyCode::ControlRight]);

    if control && keyboard_input.just_pressed(KeyCode::W) {
        wireframe.global = !wireframe.global;
    }
}
