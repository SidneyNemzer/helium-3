//! A simple 3D scene with light shining over a cube sitting on a plane.

use bevy::{
    pbr::{MaterialPipeline, MaterialPipelineKey},
    prelude::*,
    render::{
        mesh::MeshVertexBufferLayout,
        render_resource::{
            AsBindGroup, PolygonMode, PrimitiveTopology, RenderPipelineDescriptor, ShaderRef,
            SpecializedMeshPipelineError,
        },
    },
};

#[derive(Component)]
pub struct Destination(Vec3);

#[derive(Bundle)]
pub struct AnimatedCamera3d {
    pub camera: Camera3dBundle,
    pub destination: Destination,
}

impl Default for AnimatedCamera3d {
    fn default() -> Self {
        AnimatedCamera3d {
            camera: Camera3dBundle {
                transform: Transform::from_translation(Vec3::ZERO).looking_at(Vec3::ZERO, Vec3::Y),
                ..default()
            },
            destination: Destination(Vec3::ZERO),
        }
    }
}

impl AnimatedCamera3d {
    pub fn update(
        time: Res<Time>,
        mut query: Query<(&mut Transform, &mut Destination), With<Camera>>,
    ) {
        let (mut transform, destination) = query.single_mut();
        let distance = transform.translation.distance(destination.0);
        let velocity = distance / 2.0;

        if distance < 0.01 {
            transform.translation = destination.0;
            transform.look_at(Vec3::ZERO, Vec3::Y);
            return;
        }

        transform.translation = transform
            .translation
            .lerp(destination.0, velocity * time.delta_seconds());
        transform.look_at(Vec3::ZERO, Vec3::Y);
    }
}

fn main() {
    App::new()
        .add_plugins((DefaultPlugins, MaterialPlugin::<LineMaterial>::default()))
        .add_plugins(bevy::diagnostic::LogDiagnosticsPlugin::default())
        .add_plugins(bevy::diagnostic::FrameTimeDiagnosticsPlugin::default())
        .add_systems(Startup, setup)
        .add_systems(Update, (position_camera, AnimatedCamera3d::update))
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut line_materials: ResMut<Assets<LineMaterial>>,
) {
    commands.insert_resource(Msaa::Sample4);

    // circular base
    commands.spawn(PbrBundle {
        mesh: meshes.add(shape::Circle::new(4.0).into()),
        material: materials.add(Color::WHITE.into()),
        transform: Transform::from_rotation(Quat::from_rotation_x(-std::f32::consts::FRAC_PI_2)),
        ..default()
    });
    // cube
    commands.spawn(PbrBundle {
        mesh: meshes.add(Mesh::from(shape::Cube { size: 1.0 })),
        material: materials.add(Color::rgb_u8(124, 144, 255).into()),
        transform: Transform::from_xyz(0.0, 0.5, 0.0),
        ..default()
    });
    // light
    commands.spawn(PointLightBundle {
        point_light: PointLight {
            intensity: 1500.0,
            shadows_enabled: true,
            ..default()
        },
        transform: Transform::from_xyz(4.0, 8.0, 4.0),
        ..default()
    });

    // Spawn a list of lines with start and end points for each lines
    commands.spawn(MaterialMeshBundle {
        mesh: meshes.add(Mesh::from(LineList {
            lines: vec![
                (Vec3::ZERO, Vec3::new(1.0, 1.0, 0.0)),
                (Vec3::new(1.0, 1.0, 0.0), Vec3::new(1.0, 0.0, 0.0)),
            ],
        })),
        transform: Transform::from_xyz(-1.5, 2.0, 0.0),
        material: line_materials.add(LineMaterial {
            color: Color::GREEN,
        }),
        ..default()
    });

    // Spawn a line strip that goes from point to point
    commands.spawn(MaterialMeshBundle {
        mesh: meshes.add(Mesh::from(LineStrip {
            points: vec![
                Vec3::ZERO,
                Vec3::new(1.0, 1.0, 0.0),
                Vec3::new(1.0, 0.0, 0.0),
            ],
        })),
        transform: Transform::from_xyz(0.5, 2.0, 0.0),
        material: line_materials.add(LineMaterial { color: Color::BLUE }),
        ..default()
    });

    // camera
    commands.spawn(AnimatedCamera3d {
        camera: Camera3dBundle {
            transform: Transform::from_translation(DEFAULT_CAMERA_POSITION)
                .looking_at(Vec3::ZERO, Vec3::Y),
            ..default()
        },
        destination: Destination(DEFAULT_CAMERA_POSITION),
    });
}

const DEFAULT_CAMERA_POSITION: Vec3 = Vec3::new(-2.5, 4.5, 9.0);

fn position_camera(
    mut destination: Query<&mut Destination, With<Camera>>,
    windows: Query<&Window, With<bevy::window::PrimaryWindow>>,
) {
    let mut destination = destination.single_mut();
    let window = windows.single();

    if let Some(position) = window.cursor_position() {
        let x_offset = (position.x / window.width() * 2.0 - 1.0) * 10.0;
        let y_offset = (position.y / window.height() * 2.0 - 1.0) * 10.0;

        let translation = DEFAULT_CAMERA_POSITION + Vec3::new(x_offset, -y_offset, 0.0);
        destination.0 = translation;
    } else {
        // cursor isn't inside the window
        destination.0 = DEFAULT_CAMERA_POSITION;
    }
}

#[derive(Asset, TypePath, Default, AsBindGroup, Debug, Clone)]
struct LineMaterial {
    #[uniform(0)]
    color: Color,
}

impl Material for LineMaterial {
    fn fragment_shader() -> ShaderRef {
        "line_material.wgsl".into()
    }

    fn specialize(
        _pipeline: &MaterialPipeline<Self>,
        descriptor: &mut RenderPipelineDescriptor,
        _layout: &MeshVertexBufferLayout,
        _key: MaterialPipelineKey<Self>,
    ) -> Result<(), SpecializedMeshPipelineError> {
        // This is the important part to tell bevy to render this material as a
        // line between vertices
        descriptor.primitive.polygon_mode = PolygonMode::Line;
        Ok(())
    }
}

/// A list of lines with a start and end position
#[derive(Debug, Clone)]
pub struct LineList {
    pub lines: Vec<(Vec3, Vec3)>,
}

impl From<LineList> for Mesh {
    fn from(line: LineList) -> Self {
        let vertices: Vec<_> = line.lines.into_iter().flat_map(|(a, b)| [a, b]).collect();

        // This tells wgpu that the positions are list of lines where every pair
        // is a start and end point
        Mesh::new(PrimitiveTopology::LineList)
            // Add the vertices positions as an attribute
            .with_inserted_attribute(Mesh::ATTRIBUTE_POSITION, vertices)
    }
}

/// A list of points that will have a line drawn between each consecutive points
#[derive(Debug, Clone)]
pub struct LineStrip {
    pub points: Vec<Vec3>,
}

impl From<LineStrip> for Mesh {
    fn from(line: LineStrip) -> Self {
        // This tells wgpu that the positions are a list of points where a line
        // will be drawn between each consecutive point
        Mesh::new(PrimitiveTopology::LineStrip)
            // Add the point positions as an attribute
            .with_inserted_attribute(Mesh::ATTRIBUTE_POSITION, line.points)
    }
}
