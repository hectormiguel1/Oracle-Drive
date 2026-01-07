//! Frame buffer for offscreen rendering with CPU readback

/// Offscreen render target with CPU-readable output buffer
pub struct FrameBuffer {
    pub texture: wgpu::Texture,
    pub view: wgpu::TextureView,
    pub output_buffer: wgpu::Buffer,
    pub width: u32,
    pub height: u32,
    format: wgpu::TextureFormat,
}

impl FrameBuffer {
    /// Create a new frame buffer with specified dimensions
    pub fn new(device: &wgpu::Device, width: u32, height: u32) -> Self {
        let format = wgpu::TextureFormat::Rgba8Unorm;

        // Create render target texture
        let texture = device.create_texture(&wgpu::TextureDescriptor {
            label: Some("VFX Frame Buffer Texture"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::COPY_SRC,
            view_formats: &[],
        });

        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());

        // Calculate buffer size with proper alignment
        // wgpu requires COPY_BYTES_PER_ROW_ALIGNMENT (256) for buffer copies
        let bytes_per_pixel = 4u32; // RGBA8
        let unpadded_bytes_per_row = width * bytes_per_pixel;
        let align = wgpu::COPY_BYTES_PER_ROW_ALIGNMENT;
        let padded_bytes_per_row = (unpadded_bytes_per_row + align - 1) / align * align;
        let buffer_size = (padded_bytes_per_row * height) as u64;

        // Create output buffer for CPU readback
        let output_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("VFX Frame Buffer Output"),
            size: buffer_size,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            mapped_at_creation: false,
        });

        Self {
            texture,
            view,
            output_buffer,
            width,
            height,
            format,
        }
    }

    /// Get the texture format
    pub fn format(&self) -> wgpu::TextureFormat {
        self.format
    }

    /// Copy rendered texture to the output buffer
    pub fn copy_to_buffer(&self, encoder: &mut wgpu::CommandEncoder) {
        let bytes_per_pixel = 4u32;
        let unpadded_bytes_per_row = self.width * bytes_per_pixel;
        let align = wgpu::COPY_BYTES_PER_ROW_ALIGNMENT;
        let padded_bytes_per_row = (unpadded_bytes_per_row + align - 1) / align * align;

        encoder.copy_texture_to_buffer(
            wgpu::TexelCopyTextureInfo {
                texture: &self.texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            wgpu::TexelCopyBufferInfo {
                buffer: &self.output_buffer,
                layout: wgpu::TexelCopyBufferLayout {
                    offset: 0,
                    bytes_per_row: Some(padded_bytes_per_row),
                    rows_per_image: Some(self.height),
                },
            },
            wgpu::Extent3d {
                width: self.width,
                height: self.height,
                depth_or_array_layers: 1,
            },
        );
    }

    /// Read pixels from the output buffer (blocking)
    pub fn read_pixels(&self, device: &wgpu::Device) -> Vec<u8> {
        let bytes_per_pixel = 4u32;
        let unpadded_bytes_per_row = self.width * bytes_per_pixel;
        let align = wgpu::COPY_BYTES_PER_ROW_ALIGNMENT;
        let padded_bytes_per_row = (unpadded_bytes_per_row + align - 1) / align * align;

        // Map the buffer for reading
        let buffer_slice = self.output_buffer.slice(..);
        let (tx, rx) = std::sync::mpsc::channel();
        buffer_slice.map_async(wgpu::MapMode::Read, move |result| {
            tx.send(result).unwrap();
        });

        // Wait for the mapping to complete
        device.poll(wgpu::Maintain::Wait);
        rx.recv().unwrap().expect("Failed to map buffer");

        // Read the data
        let data = buffer_slice.get_mapped_range();

        // Remove row padding if present
        let mut pixels = Vec::with_capacity((self.width * self.height * 4) as usize);
        for row in 0..self.height {
            let start = (row * padded_bytes_per_row) as usize;
            let end = start + (self.width * bytes_per_pixel) as usize;
            pixels.extend_from_slice(&data[start..end]);
        }

        // Unmap the buffer
        drop(data);
        self.output_buffer.unmap();

        pixels
    }

    /// Resize the frame buffer
    pub fn resize(&mut self, device: &wgpu::Device, width: u32, height: u32) {
        if self.width == width && self.height == height {
            return;
        }

        *self = Self::new(device, width, height);
    }
}
