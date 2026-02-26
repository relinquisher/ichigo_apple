import Foundation

enum JsonDataLoader {
    static func loadWords(from filename: String) -> [WordJSON] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([WordJSON].self, from: data)) ?? []
    }
}
