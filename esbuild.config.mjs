import * as esbuild from "esbuild"
import vuePlugin from "esbuild-plugin-vue3"

const watch = process.argv.includes("--watch")

const context = await esbuild.context({
  entryPoints: ["app/javascript/application.js"],
  bundle: true,
  sourcemap: true,
  format: "esm",
  outdir: "app/assets/builds",
  publicPath: "/assets",
  plugins: [vuePlugin()],
  loader: {
    ".png": "file",
    ".svg": "file",
  },
})

if (watch) {
  await context.watch()
  console.log("Watching for changes...")
} else {
  await context.rebuild()
  await context.dispose()
}
