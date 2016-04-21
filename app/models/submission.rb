class Submission

    def sourceCode
        file = File.join(Rails.root, 'testcode.js')
        File.read(file)
    end
end