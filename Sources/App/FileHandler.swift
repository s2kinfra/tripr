
import Multipart
import Foundation
import Node
import Vapor

class FileHandler {
    
    
    static func getFilesInDir(dirname: String) throws -> [String] {
        let fileMngr=FileManager.default;
        return try fileMngr.contentsOfDirectory(atPath:dirname);
    }
    
    fileprivate static func createDir(dirName: String) throws {
        
        if FileManager.default.fileExists(atPath: dirName) { return }
        do {
            try FileManager.default.createDirectory(atPath: dirName, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            throw error
        }
    }

    static func uploadFile(user: User , request: Request) throws {
        
        guard let file = request.formData?["file"], var fileName = file.filename else {
            throw Abort(.badRequest, reason: "No file! 😱")
        }
        let workDir = Config.workingDirectory()
        
        try FileHandler.createDir(dirName: "\(workDir)public/uploads/\(user.username)/")
        fileName = fileName.replacingOccurrences(of: " ", with: "_")
        
        if fileName.characters.count > 15 {
            fileName.insert("-", at: fileName.index(fileName.startIndex, offsetBy: 15))
        }
        if fileName.characters.count > 30 {
            fileName.insert("-", at: fileName.index(fileName.startIndex, offsetBy: 30))
        }
        
        try Data(file.part.body).write(to: URL(fileURLWithPath: "\(workDir)public/uploads/\(user.username)/\(fileName)"))
        
        
        let fileModel = File.init(name: fileName, path: "/uploads/\(user.username)/\(fileName)", absolutePath: "\(workDir)public/uploads/\(user.username)/\(fileName)", user_id: user.id!, type: .image)
        
        try fileModel.save()
        
    }
    

}
