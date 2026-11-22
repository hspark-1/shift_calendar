"""실제 제품 SwiftUI의 family별 검토 이미지를 생성한다. 실제 WidgetKit host 인수는 아니다."""
from pathlib import Path
import argparse
import json
import os
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True, help='실행할 Simulator UUID')
    parser.add_argument('--output', type=Path, default=Path('/private/tmp/shiftmate-widget-design-render'))
    parser.add_argument('--ruby', default='ruby')
    parser.add_argument('--gem-home', help='xcodeproj gem을 제공하는 기존 GEM_HOME')
    args = parser.parse_args()
    project_root = Path(__file__).resolve().parents[2]
    output_root = args.output.resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    product = project_root / 'ios/ShiftMateWidget/ShiftMateWidget.swift'
    source = product.read_text().split('struct ShiftMateShiftWidget: Widget')[0]
    family_environment = '@Environment(\\.widgetFamily) private var family'
    if source.count(family_environment) != 1:
        raise RuntimeError('제품 family 진입점이 바뀌었습니다. 렌더러를 확인하세요.')
    # WidgetFamily는 읽기 전용 환경값이다. 임시 표시 사본에서만 주입 인자로 바꾼다.
    (output_root / 'ShiftMateWidgetView.swift').write_text(source.replace(family_environment, 'let family: WidgetFamily'))
    tests = Path(__file__).with_name('WidgetRenderTests.swift').read_text()
    # Simulator는 임의 환경값을 상속하지 않으므로 생성한 테스트 소스에 출력 경로를 넣는다.
    tests = tests.replace('ProcessInfo.processInfo.environment["WIDGET_RENDER_OUTPUT"]!', json.dumps(str(output_root / 'renders')))
    (output_root / 'WidgetRenderTests.swift').write_text(tests)
    source_paths = [str(project_root / 'ios/ShiftMateWidget/ShiftWidgetData.swift'),
                    str(output_root / 'ShiftMateWidgetView.swift'), str(output_root / 'WidgetRenderTests.swift')]
    ruby_script = '''require 'xcodeproj'
require 'json'
root, *source_paths = JSON.parse(ARGV.fetch(0))
project = Xcodeproj::Project.new("#{root}/WidgetPreview.xcodeproj")
target = project.new_target(:unit_test_bundle, 'WidgetPreview', :ios, '17.0')
source_paths.each { |path| target.add_file_references([project.main_group.new_file(path)]) }
project.files.select { |file| file.path&.end_with?('Foundation.framework') }.each do |file|
  file.path = 'System/Library/Frameworks/Foundation.framework'
  file.source_tree = 'SDKROOT'
end
target.build_configurations.each do |configuration|
  configuration.build_settings.merge!({ 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.hspark.shiftmate.WidgetPreviewTests', 'GENERATE_INFOPLIST_FILE' => 'YES', 'SWIFT_VERSION' => '5.0', 'CODE_SIGNING_ALLOWED' => 'NO', 'TARGETED_DEVICE_FAMILY' => '1', 'SWIFT_OPTIMIZATION_LEVEL' => '-Onone' })
end
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(target)
scheme.save_as(project.path, 'WidgetPreview', true)
project.save
'''
    environment = os.environ.copy()
    if args.gem_home:
        environment['GEM_HOME'] = args.gem_home
    subprocess.run([args.ruby, '-e', ruby_script, json.dumps([str(output_root), *source_paths])], env=environment, check=True)
    command = ['xcodebuild', '-project', str(output_root / 'WidgetPreview.xcodeproj'), '-scheme', 'WidgetPreview',
               '-destination', f'id={args.device}', '-derivedDataPath', str(output_root / 'render-build'), 'test']
    with (output_root / 'render.log').open('w') as log_file:
        subprocess.run(command, stdout=log_file, stderr=subprocess.STDOUT, check=True)
    print(f'렌더 완료: {output_root / "renders"}')


if __name__ == '__main__':
    main()
