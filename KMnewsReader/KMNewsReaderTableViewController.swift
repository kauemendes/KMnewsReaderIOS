//
//  KMNewsReaderTableViewController.swift
//  KMnewsReader
//
//  Created by Kaue Mendes on 4/16/15.
//  Copyright (c) 2015 Fellas Group. All rights reserved.
//

import UIKit

import CoreData

class KMNewsReaderTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var manageObjectContext: NSManagedObjectContext?
    var fetchedResultController = NSFetchedResultsController()
    var session: NSURLSession?
    var newsArray: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: sessionConfig)
        
        self.setupCoreDataStack()
        println("Executando > setupCoreData")
        
        self.getFetchedResultController()
        println("Executando > getFetchedResultController")
        
        self.getJsonResults()
        println("Executando > getJsonResults")
        
//        self.preLoadDatabase()
        println("Executando > preLoadDatabase")
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "doRefresh", forControlEvents: .ValueChanged)
        refreshControl?.tintColor = UIColor.redColor()

    }
    
    func getJsonResults(){
        //URL de acesso a API do itunes, que retorna o aplicativo gratuito no topo do ranking na app store
        var url = NSURL (string:"http://127.0.0.1:8888/index.json")
        
        var task = session!.dataTaskWithURL( url!,
            completionHandler: {
                (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
                
                if (error != nil) {
                    println(error.localizedDescription)
                } else {
                    let string = NSString(data: data, encoding: NSUTF8StringEncoding)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        println("Executando > Executando o JSON")
                        self.getNewsJSON(data)
                        self.tableView.reloadData()
                    })
                    
                    
                }
        })
        task.resume()
    }

    func doRefresh(){
        
        println("Executando > Deletando")
        self.deleteData()
        println("Executando > Deletado")
        
        self.getJsonResults()
        println("Executando > getJsonResults")
        
        println("Executando > Deletando")
        self.deleteData()
        println("Executando > Deletado")
        
//        self.preLoadDatabase()

        
        
//        NSTimer(timeInterval: 2.0, target: refreshControl!, selector: "endRefreshing", userInfo: nil, repeats: false)
        refreshControl?.endRefreshing()
    }
    

    func deleteData(){
        
        for result in fetchedResultController.fetchedObjects!  {
            println("ENtrando gosotos \(result)")
            manageObjectContext?.deleteObject(result as! NSManagedObject)
        }
        
        manageObjectContext?.save(nil)
    }
    
    
    // Esse Func responsavel por criar o CORE DATA
    func setupCoreDataStack() {
        // Criação do modelo
        let modelURL:NSURL? = NSBundle.mainBundle().URLForResource("news", withExtension: "momd")
        
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        
        // Criação do coordenador
        // INSTANCIAR um coordinator associado ao model ja criado
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        
        
        // Pegar o caminho para a pasta documents do sistema
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let applicationDocumentDirectory = urls.last as! NSURL
        
        // Criar uma URL do caminho da pasta documents + o nome do arquivo de banco de dados
        let url = applicationDocumentDirectory.URLByAppendingPathComponent("news.sqlite")
        var error:NSError? = nil
        NSLog("%@", url)
        
        
        // associar o arquivo de persistencia com o coordinator, especificado o tipo (SQLLITE)
        var store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error)
        
        //se ocorrer um erro na criacao do arquivo de persistencia, logar
        if store == nil {
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            return
        }
        
        // Criação do Contexto
        manageObjectContext = NSManagedObjectContext()
        manageObjectContext!.persistentStoreCoordinator = coordinator
        
    }
    
    func preLoadDatabase(){
        //carrega somente se o banco nunca foi pre carregado
//        if (NSUserDefaults.standardUserDefaults().objectForKey("bancoJaCarregado") == nil) {
        
            let entityDescripition = NSEntityDescription.entityForName("News", inManagedObjectContext: manageObjectContext!)
            
            for noticias in self.newsArray {
                let news = News(entity: entityDescripition!, insertIntoManagedObjectContext: manageObjectContext)
                news.title = noticias
            }
            
            manageObjectContext!.save(nil)
            
//            NSUserDefaults.standardUserDefaults().setValue("S", forKey: "bancoJaCarregado")
//            NSUserDefaults.standardUserDefaults().synchronize()
//        }
    }
    
    func getFetchedResultController() {
        //Primeiro inicializamos um FetchRequest com dados da tabela Task
        let fetchRequest = NSFetchRequest( entityName: "News")
        
        // Definimos que o campo usado para ordenação será "nome”
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        //cria um predicao que seleciona só o status com tipo 'completa’
        //        fetchRequest.predicate = NSPredicate(format: "status.tipo like 'completa'")
        
        //Iniciamos a propriedade fetchedResultController com uma instância de  NSFetchedResultsController
        //com o FetchRequest acima definido e sem opções de cache
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: manageObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        //a controller será o delegate do fetch”
        fetchedResultController.delegate = self
        
        
        //Executa o Fetch
        fetchedResultController.performFetch(nil)
    }
    
    func getNewsJSON(data: NSData) -> [String:AnyObject]? {
        var jsonError: NSError?
        //cria um dicionario [String:AnyObject] do JSON
        if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)  as? [String:AnyObject]{
            //            println(json)
            let entityDescripition = NSEntityDescription.entityForName("News", inManagedObjectContext: manageObjectContext!)
            
            for artigos in json["articles"] as! [[String : AnyObject]] {
                if let title: String = artigos["title"] as? String {
                    let news = News(entity: entityDescripition!, insertIntoManagedObjectContext: manageObjectContext)
                    news.title = title
                }
            }
            
             manageObjectContext!.save(nil)
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        let numbersOfRowsInSection = fetchedResultController.fetchedObjects?.count
        
        return numbersOfRowsInSection!
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell
        
        // Configure the cell...
        let news = fetchedResultController.objectAtIndexPath(indexPath) as! News

        if let title = news.title as? String {
            cell.textLabel?.text = title
        }
        
        
        return cell
    }

    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
