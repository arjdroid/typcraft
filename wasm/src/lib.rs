use std::sync::OnceLock;

use typst::diag::{FileError, FileResult};
use typst::foundations::{Bytes, Datetime};
use typst::syntax::{FileId, Source};
use typst::text::{Font, FontBook};
use typst::utils::LazyHash;
use typst::{Library, LibraryExt, World};
use typst_library::layout::PagedDocument;
use wasm_bindgen::prelude::*;

/// Embedded fonts
static FONTS: OnceLock<(LazyHash<FontBook>, Vec<Font>)> = OnceLock::new();

/// Get or initialize fonts from typst-assets
fn fonts() -> &'static (LazyHash<FontBook>, Vec<Font>) {
    FONTS.get_or_init(|| {
        let mut book = FontBook::new();
        let mut fonts = Vec::new();

        // Load fonts from typst-assets
        for font_data in typst_assets::fonts() {
            let buffer = Bytes::new(font_data.to_vec());
            for font in Font::iter(buffer) {
                book.push(font.info().clone());
                fonts.push(font);
            }
        }

        (LazyHash::new(book), fonts)
    })
}

/// A minimal World implementation for compiling Typst math in WASM
pub struct MathWorld {
    library: LazyHash<Library>,
    source: Source,
}

impl MathWorld {
    pub fn new(math_content: &str) -> Self {
        // Wrap the math content in a minimal Typst document
        let source_code = format!(
            "#set page(width: auto, height: auto, margin: 0.5em)\n\
             #set text(size: 16pt)\n\
             ${}$",
            math_content
        );

        let source = Source::detached(&source_code);

        MathWorld {
            library: LazyHash::new(Library::builder().build()),
            source,
        }
    }
}

impl World for MathWorld {
    fn library(&self) -> &LazyHash<Library> {
        &self.library
    }

    fn book(&self) -> &LazyHash<FontBook> {
        &fonts().0
    }

    fn main(&self) -> FileId {
        self.source.id()
    }

    fn source(&self, id: FileId) -> FileResult<Source> {
        if id == self.source.id() {
            Ok(self.source.clone())
        } else {
            Err(FileError::NotFound(id.vpath().as_rootless_path().into()))
        }
    }

    fn file(&self, id: FileId) -> FileResult<Bytes> {
        Err(FileError::NotFound(id.vpath().as_rootless_path().into()))
    }

    fn font(&self, index: usize) -> Option<Font> {
        fonts().1.get(index).cloned()
    }

    fn today(&self, _offset: Option<i64>) -> Option<Datetime> {
        None
    }
}

/// Initialize panic hook for better error messages in WASM
#[wasm_bindgen(start)]
pub fn init() {
    console_error_panic_hook::set_once();
}

/// Render a Typst math expression to SVG
#[wasm_bindgen(js_name = "renderMath")]
pub fn render_math(expression: &str) -> Result<String, String> {
    let world = MathWorld::new(expression);

    // Compile the document
    let result = typst::compile::<PagedDocument>(&world);

    match result.output {
        Ok(document) => {
            // Render first page to SVG
            if let Some(page) = document.pages.first() {
                let svg = typst_svg::svg(page);
                Ok(svg)
            } else {
                Err("No pages in document".to_string())
            }
        }
        Err(errors) => {
            let error_msgs: Vec<String> = errors
                .iter()
                .map(|e| e.message.to_string())
                .collect();
            Err(error_msgs.join("; "))
        }
    }
}
