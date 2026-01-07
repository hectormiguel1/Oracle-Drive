//! VFX GPU Renderer Module
//!
//! Provides headless GPU rendering for VFX effects using wgpu.
//! Renders to an offscreen buffer and returns RGBA pixel data.

mod context;
mod frame_buffer;
mod pipeline;

pub use context::GpuContext;
pub use frame_buffer::FrameBuffer;
pub use pipeline::{ParticlePipeline, Vertex, Uniforms, MaterialUniforms};

use anyhow::Result;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use wgpu::util::DeviceExt;

use super::structs::{VfxModel, VfxMesh, VfxVertex};

/// VFX Player state
pub struct VfxPlayer {
    pub context: GpuContext,
    pub frame_buffer: FrameBuffer,
    pub pipeline: ParticlePipeline,
    pub animation: AnimationState,
    pub loaded_model: Option<LoadedModel>,
    running: Arc<AtomicBool>,
}

/// Animation state for time-based effects
pub struct AnimationState {
    pub time: f32,
    pub rotation_y: f32,
    pub scale: f32,
    pub alpha: f32,
}

impl Default for AnimationState {
    fn default() -> Self {
        Self {
            time: 0.0,
            rotation_y: 0.0,
            scale: 1.0,
            alpha: 1.0,
        }
    }
}

impl AnimationState {
    pub fn update(&mut self, delta: f32) {
        self.time += delta;

        // Simple rotation (1 rotation per 4 seconds)
        self.rotation_y = self.time * std::f32::consts::PI * 0.5;

        // Pulsing scale (0.9 to 1.1)
        self.scale = 1.0 + 0.1 * (self.time * 2.0).sin();

        // Fade in/out cycle (3 second period)
        self.alpha = 0.7 + 0.3 * (self.time * std::f32::consts::TAU / 3.0).sin();
    }

    pub fn reset(&mut self) {
        self.time = 0.0;
        self.rotation_y = 0.0;
        self.scale = 1.0;
        self.alpha = 1.0;
    }
}

/// Loaded model ready for GPU rendering
pub struct LoadedModel {
    pub vertex_buffer: wgpu::Buffer,
    pub index_buffer: wgpu::Buffer,
    pub index_count: u32,
    pub texture: wgpu::Texture,
    pub texture_view: wgpu::TextureView,
    pub texture_bind_group: wgpu::BindGroup,
    pub material_buffer: wgpu::Buffer,
    pub material_bind_group: wgpu::BindGroup,
    pub diffuse_color: [f32; 4],
}

impl VfxPlayer {
    /// Create a new VFX player with specified render dimensions
    pub fn new(width: u32, height: u32) -> Result<Self> {
        let context = pollster::block_on(GpuContext::new())?;
        let frame_buffer = FrameBuffer::new(&context.device, width, height);
        let pipeline = ParticlePipeline::new(&context.device, frame_buffer.format());

        Ok(Self {
            context,
            frame_buffer,
            pipeline,
            animation: AnimationState::default(),
            loaded_model: None,
            running: Arc::new(AtomicBool::new(false)),
        })
    }

    /// Check if the player is currently streaming
    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::SeqCst)
    }

    /// Set the running state
    pub fn set_running(&self, running: bool) {
        self.running.store(running, Ordering::SeqCst);
    }

    /// Get a clone of the running flag for thread-safe checking
    pub fn running_flag(&self) -> Arc<AtomicBool> {
        Arc::clone(&self.running)
    }

    /// Render a single frame and return RGBA bytes
    pub fn render_frame(&mut self, delta: f32) -> Result<Vec<u8>> {
        self.animation.update(delta);

        // Create uniforms with current animation state
        let aspect = self.frame_buffer.width as f32 / self.frame_buffer.height as f32;
        let uniforms = self.build_uniforms(aspect);

        // Update uniform buffer
        self.context.queue.write_buffer(
            &self.pipeline.uniform_buffer,
            0,
            bytemuck::cast_slice(&[uniforms]),
        );

        // Begin render pass
        let mut encoder = self.context.device.create_command_encoder(
            &wgpu::CommandEncoderDescriptor { label: Some("VFX Render Encoder") }
        );

        {
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("VFX Render Pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &self.frame_buffer.view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color {
                            r: 0.0,
                            g: 0.0,
                            b: 0.0,
                            a: 0.0,
                        }),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                timestamp_writes: None,
                occlusion_query_set: None,
            });

            render_pass.set_pipeline(&self.pipeline.render_pipeline);
            render_pass.set_bind_group(0, &self.pipeline.uniform_bind_group, &[]);

            if let Some(model) = &self.loaded_model {
                render_pass.set_bind_group(1, &model.texture_bind_group, &[]);
                render_pass.set_bind_group(2, &model.material_bind_group, &[]);
                render_pass.set_vertex_buffer(0, model.vertex_buffer.slice(..));
                render_pass.set_index_buffer(model.index_buffer.slice(..), wgpu::IndexFormat::Uint16);
                render_pass.draw_indexed(0..model.index_count, 0, 0..1);
            }
        }

        // Copy texture to buffer for CPU readback
        self.frame_buffer.copy_to_buffer(&mut encoder);
        self.context.queue.submit(std::iter::once(encoder.finish()));

        // Read pixels back
        let pixels = self.frame_buffer.read_pixels(&self.context.device);
        Ok(pixels)
    }

    fn build_uniforms(&self, aspect: f32) -> Uniforms {
        // Build MVP matrix
        let projection = perspective_matrix(45.0_f32.to_radians(), aspect, 0.1, 100.0);
        let view = look_at_matrix(
            [0.0, 0.0, 3.0],
            [0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
        );
        let model = rotation_y_matrix(self.animation.rotation_y);
        let scale = scale_matrix(self.animation.scale);

        let mvp = mat4_multiply(&projection, &mat4_multiply(&view, &mat4_multiply(&model, &scale)));

        Uniforms {
            mvp,
            time: self.animation.time,
            alpha: self.animation.alpha,
            _padding: [0.0; 2],
        }
    }
}

// Matrix helper functions
fn perspective_matrix(fov: f32, aspect: f32, near: f32, far: f32) -> [[f32; 4]; 4] {
    let f = 1.0 / (fov / 2.0).tan();
    [
        [f / aspect, 0.0, 0.0, 0.0],
        [0.0, f, 0.0, 0.0],
        [0.0, 0.0, (far + near) / (near - far), -1.0],
        [0.0, 0.0, (2.0 * far * near) / (near - far), 0.0],
    ]
}

fn look_at_matrix(eye: [f32; 3], center: [f32; 3], up: [f32; 3]) -> [[f32; 4]; 4] {
    let f = normalize([
        center[0] - eye[0],
        center[1] - eye[1],
        center[2] - eye[2],
    ]);
    let s = normalize(cross(f, up));
    let u = cross(s, f);

    [
        [s[0], u[0], -f[0], 0.0],
        [s[1], u[1], -f[1], 0.0],
        [s[2], u[2], -f[2], 0.0],
        [-dot(s, eye), -dot(u, eye), dot(f, eye), 1.0],
    ]
}

fn rotation_y_matrix(angle: f32) -> [[f32; 4]; 4] {
    let c = angle.cos();
    let s = angle.sin();
    [
        [c, 0.0, s, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [-s, 0.0, c, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
}

fn scale_matrix(s: f32) -> [[f32; 4]; 4] {
    [
        [s, 0.0, 0.0, 0.0],
        [0.0, s, 0.0, 0.0],
        [0.0, 0.0, s, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
}

fn mat4_multiply(a: &[[f32; 4]; 4], b: &[[f32; 4]; 4]) -> [[f32; 4]; 4] {
    let mut result = [[0.0; 4]; 4];
    for i in 0..4 {
        for j in 0..4 {
            for k in 0..4 {
                result[i][j] += a[i][k] * b[k][j];
            }
        }
    }
    result
}

fn normalize(v: [f32; 3]) -> [f32; 3] {
    let len = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt();
    if len > 0.0 {
        [v[0] / len, v[1] / len, v[2] / len]
    } else {
        v
    }
}

fn cross(a: [f32; 3], b: [f32; 3]) -> [f32; 3] {
    [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    ]
}

fn dot(a: [f32; 3], b: [f32; 3]) -> f32 {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

impl VfxPlayer {
    /// Load a VFX model with its texture for rendering
    pub fn load_model(&mut self, model: &VfxModel, texture_rgba: &[u8], tex_width: u32, tex_height: u32) -> Result<()> {
        let device = &self.context.device;
        let queue = &self.context.queue;

        // Get mesh data (use default quad if none)
        let mesh = model.mesh.as_ref()
            .map(|m| m.clone())
            .unwrap_or_else(create_default_quad);

        // Convert VfxVertex to renderer Vertex
        let vertices: Vec<Vertex> = mesh.vertices.iter()
            .map(|v| Vertex {
                position: v.position,
                uv: v.uv,
            })
            .collect();

        // Create vertex buffer
        let vertex_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("VFX Vertex Buffer"),
            contents: bytemuck::cast_slice(&vertices),
            usage: wgpu::BufferUsages::VERTEX,
        });

        // Create index buffer
        let index_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("VFX Index Buffer"),
            contents: bytemuck::cast_slice(&mesh.indices),
            usage: wgpu::BufferUsages::INDEX,
        });

        let index_count = mesh.indices.len() as u32;

        // Create texture from RGBA data
        let texture_size = wgpu::Extent3d {
            width: tex_width,
            height: tex_height,
            depth_or_array_layers: 1,
        };

        let texture = device.create_texture(&wgpu::TextureDescriptor {
            label: Some("VFX Model Texture"),
            size: texture_size,
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8UnormSrgb,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });

        queue.write_texture(
            wgpu::TexelCopyTextureInfo {
                texture: &texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            texture_rgba,
            wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(4 * tex_width),
                rows_per_image: Some(tex_height),
            },
            texture_size,
        );

        let texture_view = texture.create_view(&wgpu::TextureViewDescriptor::default());

        // Create texture bind group
        let texture_bind_group = self.pipeline.create_texture_bind_group(device, &texture_view);

        // Get diffuse color from material
        let diffuse_color = [
            model.material.diffuse_color[0],
            model.material.diffuse_color[1],
            model.material.diffuse_color[2],
            model.material.diffuse_color[3],
        ];

        // Create material buffer
        let material_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("VFX Material Buffer"),
            contents: bytemuck::cast_slice(&[MaterialUniforms { diffuse: diffuse_color }]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        let material_bind_group = self.pipeline.create_material_bind_group(device, &material_buffer);

        self.loaded_model = Some(LoadedModel {
            vertex_buffer,
            index_buffer,
            index_count,
            texture,
            texture_view,
            texture_bind_group,
            material_buffer,
            material_bind_group,
            diffuse_color,
        });

        self.animation.reset();

        Ok(())
    }

    /// Load a simple test quad for debugging
    pub fn load_test_quad(&mut self, color: [f32; 4]) -> Result<()> {
        let device = &self.context.device;
        let queue = &self.context.queue;

        // Create a simple quad mesh
        let vertices = vec![
            Vertex { position: [-0.5, -0.5, 0.0], uv: [0.0, 1.0] },
            Vertex { position: [0.5, -0.5, 0.0], uv: [1.0, 1.0] },
            Vertex { position: [0.5, 0.5, 0.0], uv: [1.0, 0.0] },
            Vertex { position: [-0.5, 0.5, 0.0], uv: [0.0, 0.0] },
        ];
        let indices: Vec<u16> = vec![0, 1, 2, 0, 2, 3];

        let vertex_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Test Vertex Buffer"),
            contents: bytemuck::cast_slice(&vertices),
            usage: wgpu::BufferUsages::VERTEX,
        });

        let index_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Test Index Buffer"),
            contents: bytemuck::cast_slice(&indices),
            usage: wgpu::BufferUsages::INDEX,
        });

        // Create a 2x2 white texture
        let tex_data: [u8; 16] = [
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
        ];

        let texture = device.create_texture(&wgpu::TextureDescriptor {
            label: Some("Test Texture"),
            size: wgpu::Extent3d { width: 2, height: 2, depth_or_array_layers: 1 },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8UnormSrgb,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });

        queue.write_texture(
            wgpu::TexelCopyTextureInfo {
                texture: &texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            &tex_data,
            wgpu::TexelCopyBufferLayout {
                offset: 0,
                bytes_per_row: Some(8),
                rows_per_image: Some(2),
            },
            wgpu::Extent3d { width: 2, height: 2, depth_or_array_layers: 1 },
        );

        let texture_view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        let texture_bind_group = self.pipeline.create_texture_bind_group(device, &texture_view);

        let material_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Test Material Buffer"),
            contents: bytemuck::cast_slice(&[MaterialUniforms { diffuse: color }]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });
        let material_bind_group = self.pipeline.create_material_bind_group(device, &material_buffer);

        self.loaded_model = Some(LoadedModel {
            vertex_buffer,
            index_buffer,
            index_count: 6,
            texture,
            texture_view,
            texture_bind_group,
            material_buffer,
            material_bind_group,
            diffuse_color: color,
        });

        self.animation.reset();

        Ok(())
    }
}

/// Create a default quad mesh for models without geometry
fn create_default_quad() -> VfxMesh {
    VfxMesh {
        vertices: vec![
            VfxVertex { position: [-0.5, -0.5, 0.0], uv: [0.0, 1.0] },
            VfxVertex { position: [0.5, -0.5, 0.0], uv: [1.0, 1.0] },
            VfxVertex { position: [0.5, 0.5, 0.0], uv: [1.0, 0.0] },
            VfxVertex { position: [-0.5, 0.5, 0.0], uv: [0.0, 0.0] },
        ],
        indices: vec![0, 1, 2, 0, 2, 3],
        primitive_type: super::structs::VfxPrimitiveType::TriangleList,
    }
}
